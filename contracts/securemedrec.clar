;; Define a data structure for a medical record
(define-map medical-records-map
  {record-id: uint}
  {
    owner: principal,
    record-content: (buff 1000)
  }
)

;; Define a data structure for access permissions
(define-map record-access-map
  {record-id: uint, authorized-user: principal}
  {
    is-authorized: bool,
    expiry-block-height: (optional uint)
  }
)

;; Define a data structure for the audit trail
(define-data-var audit-trail-index uint u0)
(define-map audit-trail-map
  {index: uint}
  {
    record-id: uint,
    user: principal,
    action: (string-ascii 50),
    timestamp: uint
  }
)

;; Function to log actions to the audit trail
(define-private (log-action (record-id uint) (action (string-ascii 50)))
  (let ((current-index (var-get audit-trail-index)))
    (map-insert audit-trail-map
      {index: current-index}
      {
        record-id: record-id,
        user: tx-sender,
        action: action,
        timestamp: block-height
      }
    )
    (var-set audit-trail-index (+ current-index u1))
    (ok true)
  )
)

;; Function to create a new medical record
(define-public (create-medical-record (record-id uint) (encrypted-content (buff 1000)))
  (let ((sender tx-sender))
    (asserts! (> record-id u0) (err u15)) ;; Validate record-id
    (asserts! (> (len encrypted-content) u0) (err u24)) ;; Validate encrypted-content is not empty
    (if (map-insert medical-records-map
          {record-id: record-id}
          {
            owner: sender,
            record-content: encrypted-content
          })
      (begin
        (asserts! (is-ok (log-action record-id "Record Created")) (err u20))
        (ok true))
      (err u2)) ;; Failed to create record
  )
)

;; Function to grant or update access to a medical record
(define-public (grant-record-access (record-id uint) (user principal) (expiry (optional uint)))
  (let ((sender tx-sender))
    (asserts! (> record-id u0) (err u16)) ;; Validate record-id
    (asserts! (not (is-eq user sender)) (err u26)) ;; Validate user is not the sender
    (match (map-get? medical-records-map {record-id: record-id})
      record 
        (if (is-eq sender (get owner record))
          (begin
            (asserts! (match expiry 
                        some-expiry (> some-expiry block-height)
                        true)
                      (err u17)) ;; Validate expiry if provided
            (if (map-insert record-access-map
                  {record-id: record-id, authorized-user: user}
                  {
                    is-authorized: true,
                    expiry-block-height: expiry
                  })
              (begin
                (asserts! (is-ok (log-action record-id "Access Granted")) (err u21))
                (ok true))
              (err u4))) ;; Failed to grant access
          (err u5)) ;; Not Authorized to Grant Access
      (err u6)) ;; Record Not Found
  )
)

;; Function to revoke access to a medical record
(define-public (revoke-record-access (record-id uint) (user principal))
  (let ((sender tx-sender))
    (asserts! (> record-id u0) (err u18)) ;; Validate record-id
    (asserts! (not (is-eq user sender)) (err u27)) ;; Validate user is not the sender
    (match (map-get? medical-records-map {record-id: record-id})
      record (if (is-eq sender (get owner record))
        (if (map-insert record-access-map
              {record-id: record-id, authorized-user: user}
              {
                is-authorized: false,
                expiry-block-height: none
              })
          (begin
            (asserts! (is-ok (log-action record-id "Access Revoked")) (err u22))
            (ok true))
          (err u8)) ;; Failed to revoke access
        (err u9)) ;; Not Authorized to Revoke Access
      (err u10)) ;; Record Not Found
  )
)

;; Function to access a medical record
(define-public (access-medical-record (record-id uint))
  (let ((sender tx-sender)
        (current-block-height block-height))
    (asserts! (> record-id u0) (err u19)) ;; Validate record-id
    (match (map-get? record-access-map {record-id: record-id, authorized-user: sender})
      permission (if (and (get is-authorized permission)
                          (or (is-none (get expiry-block-height permission))
                              (>= (default-to u0 (get expiry-block-height permission)) current-block-height)))
        (match (map-get? medical-records-map {record-id: record-id})
          record (begin
                   (asserts! (is-ok (log-action record-id "Record Accessed")) (err u23))
                   (ok (get record-content record)))
          (err u12)) ;; Record Not Found
        (err u13)) ;; Access Denied or Expired
      (err u14)) ;; No Permission
  )
)