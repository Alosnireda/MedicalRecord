;; Define a data structure for a medical record
(define-map medical-records-map
  {record-id: int} ;; unique identifier for each record
  {
    owner: principal,
    record-content: (buff 1000) ;; encrypted data storage
  }
)

;; Define a data structure for access permissions
(define-map record-access-map
  {record-id: int, authorized-user: principal}
  {
    is-authorized: bool,
    expiry-block-height: (optional uint) ;; time-limited access
  }
)

;; Define a data structure for the audit trail
(define-data-var audit-trail-index uint u0)
(define-map audit-trail-map
  {index: uint}
  {
    record-id: int,
    user: principal,
    action: (string-ascii 50),
    timestamp: uint
  }
)

;; Function to log actions to the audit trail
(define-private (log-action (record-id int) (action (string-ascii 50)))
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
(define-public (create-medical-record (record-id int) (encrypted-content (buff 1000)))
  (let ((sender tx-sender))
    (if (map-insert medical-records-map
          {record-id: record-id}
          {
            owner: sender,
            record-content: encrypted-content
          })
      (begin
        (asserts! (is-ok (log-action record-id "Record Created")) (err u1))
        (ok true))
      (err u2)) ;; Failed to create record
  )
)

;; Function to grant or update access to a medical record
(define-public (grant-record-access (record-id int) (user principal) (expiry (optional uint)))
  (let ((sender tx-sender))
    (match (map-get? medical-records-map {record-id: record-id})
      record (if (is-eq sender (get owner record))
        (if (map-insert record-access-map
              {record-id: record-id, authorized-user: user}
              {
                is-authorized: true,
                expiry-block-height: expiry
              })
          (begin
            (asserts! (is-ok (log-action record-id "Access Granted")) (err u3))
            (ok true))
          (err u4)) ;; Failed to grant access
        (err u5)) ;; Not Authorized to Grant Access
      (err u6)) ;; Record Not Found
  )
)

;; Function to revoke access to a medical record
(define-public (revoke-record-access (record-id int) (user principal))
  (let ((sender tx-sender))
    (match (map-get? medical-records-map {record-id: record-id})
      record (if (is-eq sender (get owner record))
        (if (map-insert record-access-map
              {record-id: record-id, authorized-user: user}
              {
                is-authorized: false,
                expiry-block-height: none
              })
          (begin
            (asserts! (is-ok (log-action record-id "Access Revoked")) (err u7))
            (ok true))
          (err u8)) ;; Failed to revoke access
        (err u9)) ;; Not Authorized to Revoke Access
      (err u10)) ;; Record Not Found
  )
)

;; Function to access a medical record
(define-public (access-medical-record (record-id int))
  (let ((sender tx-sender)
        (current-block-height block-height))
    (match (map-get? record-access-map {record-id: record-id, authorized-user: sender})
      permission (if (and (get is-authorized permission)
                          (or (is-none (get expiry-block-height permission))
                              (>= (default-to u0 (get expiry-block-height permission)) current-block-height)))
        (match (map-get? medical-records-map {record-id: record-id})
          record (begin
                   (asserts! (is-ok (log-action record-id "Record Accessed")) (err u11))
                   (ok (get record-content record)))
          (err u12)) ;; Record Not Found
        (err u13)) ;; Access Denied or Expired
      (err u14)) ;; No Permission
  )
)