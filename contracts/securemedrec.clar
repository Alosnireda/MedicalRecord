;; Define a data structure for a medical record
(define-map medical-records-map
  ((record-id int)) ;; unique identifier for each record
  {
    owner principal,
    record-content (buff 1000) ;; arbitrary size for simplification, should be adjusted based on actual data requirements
  }
)

;; Define a data structure for access permissions
(define-map record-access-map
  ((record-id int) (authorized-user principal))
  ((is-authorized bool))
)

;; Function to create a new medical record
(define-public (create-medical-record (record-id int) (content (buff 1000)))
  (let ((sender principal (tx-sender)))
    (map-insert medical-records-map
      ((record-id record-id))
      {
        owner sender,
        record-content content
      })
  )
  (ok true)
)

;; Function to grant access to a medical record
(define-public (grant-record-access (record-id int) (user principal))
  (let ((sender principal (tx-sender)))
    ;; Check if the sender owns the record
    (match (map-get? medical-records-map ((record-id record-id)))
      record (if (is-eq sender (get owner record))
        (map-insert record-access-map
          ((record-id record-id) (authorized-user user))
          ((is-authorized true))
        )
        (ok false))
      ;; Record not found or not the owner
      (err "Invalid permissions"))
  )
)

;; Function to access a medical record
(define-public (access-medical-record (record-id int))
  (let ((sender principal (tx-sender)))
    ;; Check if the sender is authorized
    (match (map-get? record-access-map ((record-id record-id) (authorized-user sender)))
      permission (if (get is-authorized permission)
        (match (map-get? medical-records-map ((record-id record-id)))
          record (ok (get record-content record))
          (err "Record not found"))
        (err "Access denied"))
      ;; No permission entry found
      (err "No permission"))
  )
)
