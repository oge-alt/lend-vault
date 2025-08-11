;; Title: LendVault Protocol
;; Summary: Next-Generation Decentralized Lending Infrastructure for Bitcoin
;; Description: LendVault revolutionizes Bitcoin-native lending through an 
;;              innovative smart contract architecture that enables seamless 
;;              collateralized borrowing with dynamic risk assessment. Built 
;;              with institutional-grade security and automated liquidation 
;;              mechanisms, this protocol empowers users to unlock liquidity 
;;              from their digital assets while maintaining full custody control.
;;              Features include adaptive interest rates, multi-token support,
;;              and governance-driven parameter optimization.

;; TRAIT DEFINITIONS

;; Fungible Token Standard Interface
(define-trait ft-trait (
  (transfer
    (uint principal principal (optional (buff 34)))
    (response bool uint)
  )
  (get-balance
    (principal)
    (response uint uint)
  )
  (get-total-supply
    ()
    (response uint uint)
  )
  (get-decimals
    ()
    (response uint uint)
  )
  (get-name
    ()
    (response (string-ascii 32) uint)
  )
  (get-symbol
    ()
    (response (string-ascii 32) uint)
  )
))

;; ERROR CONSTANTS

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INSUFFICIENT-BALANCE (err u1001))
(define-constant ERR-LOAN-NOT-FOUND (err u1002))
(define-constant ERR-INVALID-LOAN-AMOUNT (err u1003))
(define-constant ERR-LOAN-ALREADY-LIQUIDATED (err u1004))
(define-constant ERR-LOAN-NOT-LIQUIDATABLE (err u1005))
(define-constant ERR-INVALID-COLLATERAL-RATIO (err u1006))
(define-constant ERR-INVALID-ADMIN-CHANGE (err u1007))

;; DATA STRUCTURES

;; Primary loan storage mapping individual loan records
(define-map loans
  {
    loan-id: uint,
    borrower: principal,
  }
  {
    collateral-amount: uint,
    borrowed-amount: uint,
    interest-rate: uint,
    start-block: uint,
    is-active: bool,
    liquidation-threshold: uint,
  }
)

;; STATE VARIABLES

;; Global loan identifier counter
(define-data-var loan-counter uint u0)

;; Protocol governance variables
(define-data-var admin-principal principal tx-sender)
(define-data-var liquidation-penalty uint u10)

;; PROTOCOL CONSTANTS

;; Risk management parameters
(define-constant MIN-COLLATERALIZATION-RATIO u150) ;; 150% minimum collateral ratio
(define-constant BASE-INTEREST-RATE u5) ;; 5% base annual interest rate
(define-constant INTEREST-RATE-MULTIPLIER u100) ;; Interest calculation multiplier
(define-constant MAX-LOAN-TERM u52560) ;; Maximum loan term (~1 year in blocks)

;; ADMINISTRATIVE FUNCTIONS

;; Transfer protocol administration to new principal
(define-public (set-admin (new-admin principal))
  (begin
    ;; Verify current admin authorization
    (asserts! (is-eq tx-sender (var-get admin-principal)) ERR-NOT-AUTHORIZED)

    ;; Validate admin change parameters
    (asserts!
      (and
        (not (is-eq new-admin (var-get admin-principal)))
        (not (is-eq new-admin tx-sender))
      )
      ERR-INVALID-ADMIN-CHANGE
    )

    (ok (var-set admin-principal new-admin))
  )
)

;; Update liquidation penalty percentage
(define-public (set-liquidation-penalty (new-penalty uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin-principal)) ERR-NOT-AUTHORIZED)
    (asserts! (< new-penalty u50) ERR-NOT-AUTHORIZED)
    (ok (var-set liquidation-penalty new-penalty))
  )
)

;; CORE LENDING FUNCTIONS

;; Create new collateralized loan position
(define-public (create-loan
    (collateral-token <ft-trait>)
    (collateral-amount uint)
    (borrow-amount uint)
  )
  (let (
      (borrower tx-sender)
      (new-loan-id (+ (var-get loan-counter) u1))
      (collateral-balance (unwrap! (contract-call? collateral-token get-balance borrower)
        ERR-INSUFFICIENT-BALANCE
      ))
      (interest-rate (calculate-dynamic-interest-rate borrow-amount))
      (liquidation-threshold (calculate-liquidation-threshold collateral-amount borrow-amount))
    )
    ;; Validate input parameters
    (asserts! (> collateral-amount u0) ERR-INVALID-LOAN-AMOUNT)
    (asserts! (>= collateral-balance collateral-amount) ERR-INSUFFICIENT-BALANCE)
    (asserts! (> borrow-amount u0) ERR-INVALID-LOAN-AMOUNT)
    (asserts! (>= liquidation-threshold MIN-COLLATERALIZATION-RATIO)
      ERR-INVALID-COLLATERAL-RATIO
    )

    ;; Transfer collateral tokens to contract custody
    (try! (contract-call? collateral-token transfer collateral-amount borrower
      (as-contract tx-sender) none
    ))

    ;; Initialize loan record in storage
    (map-set loans {
      loan-id: new-loan-id,
      borrower: borrower,
    } {
      collateral-amount: collateral-amount,
      borrowed-amount: borrow-amount,
      interest-rate: interest-rate,
      start-block: stacks-block-height,
      is-active: true,
      liquidation-threshold: liquidation-threshold,
    })

    ;; Update global loan counter
    (var-set loan-counter new-loan-id)

    (ok new-loan-id)
  )
)

;; Execute loan repayment and release collateral
(define-public (repay-loan
    (loan-id uint)
    (collateral-token <ft-trait>)
    (repayment-token <ft-trait>)
    (repayment-amount uint)
  )
  (let (
      ;; Retrieve and validate loan record
      (loan (unwrap!
        (map-get? loans {
          loan-id: loan-id,
          borrower: tx-sender,
        })
        ERR-LOAN-NOT-FOUND
      ))
      (total-repayment (calculate-total-repayment {
        borrowed-amount: (get borrowed-amount loan),
        interest-rate: (get interest-rate loan),
        start-block: (get start-block loan),
      }))
      ;; Verify token balance availability
      (repayment-balance (unwrap! (contract-call? repayment-token get-balance tx-sender)
        ERR-INSUFFICIENT-BALANCE
      ))
      (collateral-balance (unwrap!
        (contract-call? collateral-token get-balance (as-contract tx-sender))
        ERR-INSUFFICIENT-BALANCE
      ))
    )
    ;; Validate repayment conditions
    (asserts! (> loan-id u0) ERR-INVALID-LOAN-AMOUNT)
    (asserts! (get is-active loan) ERR-LOAN-ALREADY-LIQUIDATED)
    (asserts! (>= repayment-balance total-repayment) ERR-INSUFFICIENT-BALANCE)
    (asserts! (>= repayment-amount total-repayment) ERR-INSUFFICIENT-BALANCE)
    (asserts! (>= collateral-balance (get collateral-amount loan))
      ERR-INSUFFICIENT-BALANCE
    )

    ;; Process repayment transfer
    (try! (contract-call? repayment-token transfer total-repayment tx-sender
      (as-contract tx-sender) none
    ))

    ;; Return collateral to borrower
    (try! (as-contract (contract-call? collateral-token transfer (get collateral-amount loan)
      (as-contract tx-sender) tx-sender none
    )))

    ;; Close loan position
    (map-set loans {
      loan-id: loan-id,
      borrower: tx-sender,
    }
      (merge loan { is-active: false })
    )

    (ok true)
  )
)

;; Execute liquidation of undercollateralized loan
(define-public (liquidate-loan
    (loan-id uint)
    (borrower principal)
    (collateral-token <ft-trait>)
  )
  (let (
      ;; Parameter validation
      (validated-loan-id (asserts! (> loan-id u0) ERR-INVALID-LOAN-AMOUNT))
      (validated-borrower (asserts! (not (is-eq borrower tx-sender)) ERR-NOT-AUTHORIZED))
      ;; Retrieve loan information
      (loan (unwrap!
        (map-get? loans {
          loan-id: loan-id,
          borrower: borrower,
        })
        ERR-LOAN-NOT-FOUND
      ))
      (current-collateral-ratio (calculate-current-collateral-ratio {
        collateral-amount: (get collateral-amount loan),
        borrowed-amount: (get borrowed-amount loan),
      }))
      (penalty-amount (/ (* (get collateral-amount loan) (var-get liquidation-penalty)) u100))
      ;; Verify collateral availability
      (collateral-balance (unwrap!
        (contract-call? collateral-token get-balance (as-contract tx-sender))
        ERR-INSUFFICIENT-BALANCE
      ))
    )
    ;; Validate liquidation eligibility
    (asserts! (>= collateral-balance (get collateral-amount loan))
      ERR-INSUFFICIENT-BALANCE
    )
    (asserts! (get is-active loan) ERR-LOAN-ALREADY-LIQUIDATED)
    (asserts! (< current-collateral-ratio (get liquidation-threshold loan))
      ERR-LOAN-NOT-LIQUIDATABLE
    )

    ;; Transfer collateral to liquidator (minus penalty)
    (try! (as-contract (contract-call? collateral-token transfer
      (- (get collateral-amount loan) penalty-amount) (as-contract tx-sender)
      tx-sender none
    )))

    ;; Close liquidated loan position
    (map-set loans {
      loan-id: loan-id,
      borrower: borrower,
    }
      (merge loan { is-active: false })
    )

    (ok true)
  )
)