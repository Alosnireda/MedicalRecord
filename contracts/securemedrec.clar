;; Define a data structure for a medical record
(define-map medical-records-map
  ((record-id int)) ;; unique identifier for each record
  {
    owner: principal,
    record-content: (buff 1000) ;; encrypted data storage
  }
)

;; Define a data structure for access permissions
(define-map record-access-map
  ((record-id int) (authorized-user principal))
  {
    is-authorized: bool,
    expiry-block-height: (optional uint) ;; time-limited access
  }
)

;; Define a data structure for the audit trail
(define-data-var audit-trail-index uint u0)
(define-map audit-trail-map
  ((index uint))
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
      ((index current-index))
      {
        record-id: record-id,
        user: tx-sender,
        action: action,
        timestamp: block-height
      }
    )
    (var-set audit-trail-index (+ current-index u1))
  )
)

;; Function to create a new medical record
(define-public (create-medical-record (record-id int) (encrypted-content (buff 1000)))
  (let ((sender tx-sender))
    (map-insert medical-records-map
      ((record-id record-id))
      {
        owner: sender,
        record-content: encrypted-content
      }
    )
    (log-action record-id "Record Created")
    (ok true)
  )
)

;; Function to grant or update access to a medical record
(define-public (grant-record-access (record-id int) (user principal) (expiry (optional uint)))
  (let ((sender tx-sender))
    ;; Check if the sender owns the record
    (match (map-get? medical-records-map ((record-id record-id)))
      record (if (is-eq sender (get owner record))
        (begin
          (map-insert record-access-map
            ((record-id record-id) (authorized-user user))
            {
              is-authorized: true,
              expiry-block-height: expiry
            }
          )
          (log-action record-id "Access Granted")
          (ok true))
        (err "Not Authorized to Grant Access"))
      (err "Record Not Found"))
  )
)

;; Function to revoke access to a medical record
(define-public (revoke-record-access (record-id int) (user principal))
  (let ((sender tx-sender))
    ;; Check if the sender owns the record
    (match (map-get? medical-records-map ((record-id record-id)))
      record (if (is-eq sender (get owner record))
        (begin
          (map-insert record-access-map
            ((record-id record-id) (authorized-user user))
            {
              is-authorized: false,
              expiry-block-height: none
            }
          )
          (log-action record-id "Access Revoked")
          (ok true))
        (err "Not Authorized to Revoke Access"))
      (err "Record Not Found"))
  )
)

;; Function to access a medical record
(define-public (access-medical-record (record-id int))
  (let ((sender tx-sender)
        (current-block-height block-height))
    ;; Check if the sender is authorized and access has not expired
    (match (map-get? record-access-map ((record-id record-id) (authorized-user sender)))
      permission (if (and (get is-authorized permission)
                          (or (is-none (get expiry-block-height permission))
                              (>= (default-to u0 (get expiry-block-height permission)) current-block-height)))
        (begin
          (match (map-get? medical-records-map ((record-id record-id)))
            record (begin
                    (log-action record-id "Record Accessed")
                    (ok (get record-content record)))
            (err "Record Not Found"))
          (log-action record-id "Accessed Record"))
        (err "Access Denied or Expired"))
      (err "No Permission"))
  )
)
