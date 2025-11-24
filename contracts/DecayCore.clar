;; ------------------------------------------------------------
;;  Entropy Token (ENT)
;;  A Decaying Fungible Token for the Stacks Blockchain
;; ------------------------------------------------------------
;;  Concept:
;;  - Each holders balance decays by a fixed percentage
;;    over time (based on block height).
;;  - Decayed tokens are redirected to a community treasury.
;;  - Encourages use, not hoarding inspired by Silvio Gesells
;;    demurrage money concept.
;; ------------------------------------------------------------
;;  Author: Your Name
;;  License: MIT
;; ------------------------------------------------------------


;; ------------------------------------------------------------
;; Constants & Error Codes
;; ------------------------------------------------------------
(define-constant ERR-NO-BALANCE (err u400))
(define-constant ERR-INSUFFICIENT-FUNDS (err u401))
(define-constant ERR-NOT-AUTHORIZED (err u402))
(define-constant ERR-INVALID-AMOUNT (err u403))

;; ------------------------------------------------------------
;; Global Variables
;; ------------------------------------------------------------

;; Total minted supply
(define-data-var total-supply uint u0)

;; Decay configuration
(define-data-var decay-rate uint u10)        ;; 0.10% per cycle (10 = 0.10%)
(define-data-var decay-interval uint u100)   ;; 100 blocks per decay cycle

;; Community treasury (receives decayed tokens)
(define-data-var treasury principal tx-sender)
(define-data-var owner principal tx-sender)

;; Balances: track amount and last update block for each holder
(define-map balances
  {owner: principal}
  {amount: uint, last-update: uint}
)

;; ------------------------------------------------------------
;; Internal Helper: Calculate Decay
;; ------------------------------------------------------------
(define-private (apply-decay (account principal))
  (let ((info (map-get? balances {owner: account})))
    (if (is-some info)
      (let (
            (data (unwrap! info ERR-NO-BALANCE))
            (last (get last-update data))
            (blocks-since (- stacks-block-height last))
          )
        (if (>= blocks-since (var-get decay-interval))
          (let (
                (cycles (/ blocks-since (var-get decay-interval)))
                (bal (get amount data))
                (rate (/ (var-get decay-rate) u10000)) ;; convert basis points
                (decay (* bal (* rate cycles)))
                (decay-int (if (> decay bal) bal decay))
                (new-bal (- bal decay-int))
              )
            (begin
              (map-set balances {owner: account}
                {amount: new-bal, last-update: stacks-block-height})
              ;; send decayed tokens to treasury
              (let ((treasury-addr (var-get treasury)))
                (begin
                  (if (> decay-int u0)
                    (let ((treasury-info (map-get? balances {owner: treasury-addr})))
                      (if (is-some treasury-info)
                        (let ((td (unwrap! treasury-info ERR-NO-BALANCE)))
                          (map-set balances {owner: treasury-addr}
                            {amount: (+ (get amount td) decay-int),
                             last-update: stacks-block-height})
                        )
                        (map-set balances {owner: treasury-addr}
                          {amount: decay-int, last-update: stacks-block-height})
                      )
                    )
                    true
                  )
                  
                )
              )
              (ok new-bal)
            )
          )
          (ok (get amount data)) ;; no decay yet
        )
      )
      (ok u0)
    )
  )
)

;; ------------------------------------------------------------
;; Mint Function Only contract deployer
(define-public (mint (recipient principal) (amount uint))
  (begin
    (if (is-eq tx-sender (var-get owner))
      (let ((info (map-get? balances {owner: recipient})))
        (if (is-some info)
          (let ((data (unwrap! info ERR-NO-BALANCE)))
            (map-set balances {owner: recipient}
              {amount: (+ (get amount data) amount), last-update: stacks-block-height})
          )
          (map-set balances {owner: recipient}
            {amount: amount, last-update: stacks-block-height})
        )
        (var-set total-supply (+ (var-get total-supply) amount))
        (print {event: "mint", recipient: recipient, amount: amount})
        (ok true)
      )
      ERR-NOT-AUTHORIZED
    )
  )
)


;; ------------------------------------------------------------
;; Transfer Function Applies decay before transfer
;; ------------------------------------------------------------
(define-public (transfer (recipient principal) (amount uint))
  (begin
    ;; Trigger decay for both parties
    (unwrap! (apply-decay tx-sender) ERR-INVALID-AMOUNT)
    (unwrap! (apply-decay recipient) ERR-INVALID-AMOUNT)

    ;; Get sender info
    (let ((sender-info (map-get? balances {owner: tx-sender})))
      (if (is-some sender-info)
        (let ((data (unwrap! sender-info ERR-NO-BALANCE)))
          (if (>= (get amount data) amount)
            (begin
              ;; Deduct from sender
              (map-set balances {owner: tx-sender}
                {amount: (- (get amount data) amount), last-update: stacks-block-height})

              ;; Add to recipient
              (let ((rinfo (map-get? balances {owner: recipient})))
                (if (is-some rinfo)
                  (let ((rdata (unwrap! rinfo ERR-NO-BALANCE)))
                    (map-set balances {owner: recipient}
                      {amount: (+ (get amount rdata) amount), last-update: stacks-block-height})
                  )
                  (map-set balances {owner: recipient}
                    {amount: amount, last-update: stacks-block-height})
                )
              )

              (print {event: "transfer", from: tx-sender, to: recipient, amount: amount})
              (ok true)
            )
            ERR-INSUFFICIENT-FUNDS
          )
        )
        ERR-NO-BALANCE
      )
    )
  )
)

;; ------------------------------------------------------------
;; Read-Only Queries
;; ------------------------------------------------------------

(define-read-only (get-balance (account principal))
  (let ((info (map-get? balances {owner: account})))
    (if (is-some info)
      (let ((data (unwrap! info ERR-NO-BALANCE)))
        (ok (get amount data))
      )
      (ok u0)
    )
  )
)

(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

(define-read-only (get-decay-config)
  (ok {
    rate: (var-get decay-rate),
    interval: (var-get decay-interval),
    treasury: (var-get treasury)
  })
)
