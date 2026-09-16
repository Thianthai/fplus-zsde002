CLASS zcl_zsde002_ret_create DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM zcl_zsde002_doc_create_base.

  PUBLIC SECTION.

    " สร้าง Customer Return (SD Document Category = H) ผ่าน I_CustomerReturnTP
    METHODS zif_zsde002_doc_create~create REDEFINITION.

ENDCLASS.



CLASS zcl_zsde002_ret_create IMPLEMENTATION.

  METHOD zif_zsde002_doc_create~create.

    DATA lt_header        TYPE TABLE FOR CREATE i_customerreturntp.
    DATA lt_reference     TYPE TABLE FOR ACTION IMPORT i_customerreturntp~createwithreference.
    DATA lt_partner       TYPE TABLE FOR CREATE i_customerreturntp\_Partner.
    DATA lt_headerpricing TYPE TABLE FOR CREATE i_customerreturntp\_PricingElement.
    DATA lt_headertext    TYPE TABLE FOR CREATE i_customerreturntp\_Text.
    DATA lt_item          TYPE TABLE FOR CREATE i_customerreturntp\_Item.
    DATA lt_itempricing   TYPE TABLE FOR CREATE i_customerreturnitemtp\_ItemPricingElement.
    DATA lt_itemtext      TYPE TABLE FOR CREATE i_customerreturnitemtp\_ItemText.

    DATA ls_partner       TYPE STRUCTURE FOR CREATE i_customerreturntp\_Partner.
    DATA ls_headerpricing TYPE STRUCTURE FOR CREATE i_customerreturntp\_PricingElement.
    DATA ls_headertext    TYPE STRUCTURE FOR CREATE i_customerreturntp\_Text.
    DATA ls_item          TYPE STRUCTURE FOR CREATE i_customerreturntp\_Item.
    DATA ls_itempricing   TYPE STRUCTURE FOR CREATE i_customerreturnitemtp\_ItemPricingElement.
    DATA ls_itemtext      TYPE STRUCTURE FOR CREATE i_customerreturnitemtp\_ItemText.

    CLEAR gt_cid_counter.

    " Header -----------------------------------------------------------
    IF is_order-original_sales_document IS NOT INITIAL.

      " มี original_sales_document
      APPEND VALUE #( %cid   = gc_cid_header
                      %param = VALUE #( salesdocumenttype   = is_order-sales_order_type
                                        referencesddocument = is_order-original_sales_document )
                    ) TO lt_reference.

    ELSE.

      " ไม่มี original_sales_document
      APPEND VALUE #( %cid                      = gc_cid_header
                      CustomerReturnType        = is_order-sales_order_type
                      SalesOrganization         = is_order-sales_organization
                      DistributionChannel       = is_order-distribution_channel
                      OrganizationDivision      = is_order-division
                      SoldToParty               = is_order-sold_to_party
                      PurchaseOrderByCustomer   = COND #( WHEN is_order-process_type IN is_param-r_process_type_sfid
                                                          THEN is_order-customer_reference )
                      CustomerPurchaseOrderDate = to_internal_date( is_order-customer_reference_date )
                      CustomerReturnDate        = to_internal_date( is_order-document_date )
                      RequestedDeliveryDate     = to_internal_date( is_order-req_delivery_date )
                      TransactionCurrency       = is_order-currency
                      CustomerPaymentTerms      = is_order-payment_term
                      SDDocumentReason          = COND #( WHEN is_order-tran_type IN is_param-r_tran_type_reason
                                                          THEN is_order-order_reason )
                    ) TO lt_header.

    ENDIF.

    " Header Partner ---------------------------------------------------
    ls_partner-%cid_ref = gc_cid_header.

    IF is_order-ship_to_party IS NOT INITIAL.
      APPEND VALUE #( %cid                   = next_cid( `PA` )
                      PartnerFunctionForEdit = 'WE'
                      Customer               = is_order-ship_to_party
                    ) TO ls_partner-%target.
    ENDIF.

    IF is_order-bill_to_party IS NOT INITIAL.
      APPEND VALUE #( %cid                   = next_cid( `PA` )
                      PartnerFunctionForEdit = 'RE'
                      Customer               = is_order-bill_to_party
                    ) TO ls_partner-%target.
    ENDIF.

    IF is_order-payer IS NOT INITIAL.
      APPEND VALUE #( %cid                   = next_cid( `PA` )
                      PartnerFunctionForEdit = 'RG'
                      Customer               = is_order-payer
                    ) TO ls_partner-%target.
    ENDIF.

    IF  is_order-stock_van IS NOT INITIAL
    AND is_order-process_type IN is_param-r_process_type_stockvan.
      APPEND VALUE #( %cid                   = next_cid( `PA` )
                      PartnerFunctionForEdit = 'SB'
                      Customer               = is_order-stock_van
                    ) TO ls_partner-%target.
    ENDIF.

    IF ls_partner-%target IS NOT INITIAL.
      APPEND ls_partner TO lt_partner.
    ENDIF.

    " Header Pricing ---------------------------------------------------
    ls_headerpricing-%cid_ref = gc_cid_header.

    LOOP AT it_order_pricing ASSIGNING FIELD-SYMBOL(<lfs_order_pricing>).
      CHECK <lfs_order_pricing>-condition_type IS NOT INITIAL.

      APPEND VALUE #( %cid                  = next_cid( `HP` )
                      ConditionType         = <lfs_order_pricing>-condition_type
                      ConditionRateAmount   = to_internal_amount( <lfs_order_pricing>-condition_amount )
                      ConditionCurrency     = <lfs_order_pricing>-condition_currency
                      ConditionQuantity     = to_internal_quantity( <lfs_order_pricing>-condition_pricing_unit )
                      ConditionQuantityUnit = <lfs_order_pricing>-condition_unit_of_measure
                    ) TO ls_headerpricing-%target.
    ENDLOOP.

    IF ls_headerpricing-%target IS NOT INITIAL.
      APPEND ls_headerpricing TO lt_headerpricing.
    ENDIF.

    " Header Text ------------------------------------------------------
    ls_headertext-%cid_ref = gc_cid_header.

    APPEND VALUE #( %cid              = next_cid( `HT` )
                    LanguageForEdit   = gc_langu
                    LongTextIDForEdit = 'ZT01'
                    LongText          = COND #( WHEN is_order-process_type IN is_param-r_process_type_zt01
                                                THEN is_order-payment_transaction_reference )
                  ) TO ls_headertext-%target.

    APPEND VALUE #( %cid              = next_cid( `HT` )
                    LanguageForEdit   = gc_langu
                    LongTextIDForEdit = 'ZT02'
                    LongText          = COND #( WHEN is_order-process_type IN is_param-r_process_type_zt02
                                                THEN is_order-tax_document_no )
                  ) TO ls_headertext-%target.

    APPEND VALUE #( %cid              = next_cid( `HT` )
                    LanguageForEdit   = gc_langu
                    LongTextIDForEdit = 'ZT03'
                    LongText          = is_order-related_document_reference
                  ) TO ls_headertext-%target.

    APPEND VALUE #( %cid              = next_cid( `HT` )
                    LanguageForEdit   = gc_langu
                    LongTextIDForEdit = 'ZT04'
                    LongText          = COND #( WHEN is_order-order_reason IN is_param-r_order_reason_zt04
                                                THEN is_order-order_reason_text )
                  ) TO ls_headertext-%target.

    APPEND VALUE #( %cid              = next_cid( `HT` )
                    LanguageForEdit   = gc_langu
                    LongTextIDForEdit = 'ZT08'
                    LongText          = is_order-sf_header_id_ref
                  ) TO ls_headertext-%target.

    DELETE ls_headertext-%target WHERE LongText IS INITIAL.

    IF ls_headertext-%target IS NOT INITIAL.
      APPEND ls_headertext TO lt_headertext.
    ENDIF.

    " Item -------------------------------------------------------------
    ls_item-%cid_ref = gc_cid_header.

    LOOP AT it_item ASSIGNING FIELD-SYMBOL(<lfs_item>).

      DATA(lv_item_cid) = next_cid( `IT` ).

      APPEND VALUE #( %cid                       = lv_item_cid
                      Product                    = zcl_zsde002_validator=>to_internal_material( <lfs_item>-material_number )
                      MaterialByCustomer         = <lfs_item>-customer_material
                      CustomerReturnItemCategory = <lfs_item>-item_category
                      RequestedQuantity          = to_internal_quantity( <lfs_item>-requested_quantity )
                      RequestedQuantityUnit      = <lfs_item>-sales_unit
                      Plant                      = <lfs_item>-plant
                      StorageLocation            = COND #( WHEN is_order-process_type IN is_param-r_process_type_sloc
                                                           THEN <lfs_item>-storage_location )
                      Batch                      = COND #( WHEN is_order-process_type IN is_param-r_process_type_batch
                                                           THEN <lfs_item>-batch )
                    ) TO ls_item-%target.

      " Item Pricing ---------------------------------------------------
      CLEAR ls_itempricing.
      ls_itempricing-%cid_ref = lv_item_cid.

      LOOP AT it_item_pricing ASSIGNING FIELD-SYMBOL(<lfs_item_pricing>)
           WHERE item_uuid = <lfs_item>-item_uuid.

        CHECK <lfs_item_pricing>-condition_type IS NOT INITIAL.

        APPEND VALUE #( %cid                  = next_cid( `IP` )
                        ConditionType         = <lfs_item_pricing>-condition_type
                        ConditionRateAmount   = to_internal_amount( <lfs_item_pricing>-condition_amount )
                        ConditionCurrency     = <lfs_item_pricing>-condition_currency
                        ConditionQuantity     = to_internal_quantity( <lfs_item_pricing>-condition_pricing_unit )
                        ConditionQuantityUnit = <lfs_item_pricing>-condition_unit_of_measure
                      ) TO ls_itempricing-%target.
      ENDLOOP.

      IF ls_itempricing-%target IS NOT INITIAL.
        APPEND ls_itempricing TO lt_itempricing.
      ENDIF.

      " Item Text ------------------------------------------------------
      CLEAR ls_itemtext.
      ls_itemtext-%cid_ref = lv_item_cid.

      APPEND VALUE #( %cid              = next_cid( `IX` )
                      LanguageForEdit   = gc_langu
                      LongTextIDForEdit = 'ZT05'
                      LongText          = <lfs_item>-sales_text
                    ) TO ls_itemtext-%target.

      APPEND VALUE #( %cid              = next_cid( `IX` )
                      LanguageForEdit   = gc_langu
                      LongTextIDForEdit = 'ZT06'
                      LongText          = <lfs_item>-unit_text
                    ) TO ls_itemtext-%target.

      APPEND VALUE #( %cid              = next_cid( `IX` )
                      LanguageForEdit   = gc_langu
                      LongTextIDForEdit = 'ZT07'
                      LongText          = <lfs_item>-promotion_id_text
                    ) TO ls_itemtext-%target.

      APPEND VALUE #( %cid              = next_cid( `IX` )
                      LanguageForEdit   = gc_langu
                      LongTextIDForEdit = 'ZT09'
                      LongText          = COND #( WHEN is_order-process_type IN is_param-r_process_type_sfid
                                                  THEN <lfs_item>-sf_item_id_ref )
                    ) TO ls_itemtext-%target.

      DELETE ls_itemtext-%target WHERE LongText IS INITIAL.

      IF ls_itemtext-%target IS NOT INITIAL.
        APPEND ls_itemtext TO lt_itemtext.
      ENDIF.

    ENDLOOP.

    IF ls_item-%target IS NOT INITIAL.
      APPEND ls_item TO lt_item.
    ENDIF.

    " Create Customer Return -------------------------------------------
    MODIFY ENTITIES OF i_customerreturntp PRIVILEGED
      ENTITY CustomerReturn
        EXECUTE createwithreference
          FIELDS ( SalesDocumentType
                   ReferenceSDDocument )
          WITH lt_reference

        CREATE FIELDS ( CustomerReturnType
                        SalesOrganization
                        DistributionChannel
                        OrganizationDivision
                        SoldToParty
                        PurchaseOrderByCustomer
                        CustomerPurchaseOrderDate
                        CustomerReturnDate
                        RequestedDeliveryDate
                        TransactionCurrency
                        CustomerPaymentTerms
                        SDDocumentReason )
          WITH lt_header

        CREATE BY \_Partner
          FIELDS ( PartnerFunctionForEdit
                   Customer )
          WITH lt_partner

        CREATE BY \_PricingElement
          FIELDS ( ConditionType
                   ConditionRateAmount
                   ConditionCurrency
                   ConditionQuantity
                   ConditionQuantityUnit )
          WITH lt_headerpricing

        CREATE BY \_Text
          FIELDS ( LanguageForEdit
                   LongTextIDForEdit
                   LongText )
          WITH lt_headertext

        CREATE BY \_Item
          FIELDS ( Product
                   MaterialByCustomer
                   CustomerReturnItemCategory
                   RequestedQuantity
                   RequestedQuantityUnit
                   Plant
                   StorageLocation
                   Batch )
          WITH lt_item

      ENTITY CustomerReturnItem
        CREATE BY \_ItemPricingElement
          FIELDS ( ConditionType
                   ConditionRateAmount
                   ConditionCurrency
                   ConditionQuantity
                   ConditionQuantityUnit )
          WITH lt_itempricing

        CREATE BY \_ItemText
          FIELDS ( LanguageForEdit
                   LongTextIDForEdit
                   LongText )
          WITH lt_itemtext

      MAPPED   DATA(ls_mapped)
      FAILED   DATA(ls_failed)
      REPORTED DATA(ls_reported).

    " Message จาก MODIFY ENTITIES
    collect_reported( EXPORTING is_reported         = ls_reported
                                iv_sf_header_id_ref = is_order-sf_header_id_ref
                      CHANGING  ct_error            = rs_result-errors ).

    " MODIFY ENTITIES ไม่สำเร็จ
    IF ls_failed IS NOT INITIAL.
      ROLLBACK ENTITIES.
      add_summary( EXPORTING iv_msgno            = '501'
                             iv_sf_header_id_ref = is_order-sf_header_id_ref
                   CHANGING  ct_error            = rs_result-errors ).
      RETURN.
    ENDIF.

    " Commit -----------------------------------------------------------
    COMMIT ENTITIES BEGIN
      RESPONSE OF i_customerreturntp
      FAILED   DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

    IF ls_commit_failed-customerreturn IS INITIAL.
      LOOP AT ls_mapped-customerreturn ASSIGNING FIELD-SYMBOL(<lfs_key>).
        CONVERT KEY OF i_customerreturntp FROM <lfs_key>-%pid TO <lfs_key>-%key.
      ENDLOOP.
    ENDIF.

    COMMIT ENTITIES END.

    collect_reported( EXPORTING is_reported         = ls_commit_reported
                                iv_sf_header_id_ref = is_order-sf_header_id_ref
                      CHANGING  ct_error            = rs_result-errors ).

    IF ls_commit_failed IS NOT INITIAL.
      add_summary( EXPORTING iv_msgno            = '502'
                             iv_sf_header_id_ref = is_order-sf_header_id_ref
                   CHANGING  ct_error            = rs_result-errors ).
      RETURN.
    ENDIF.

    " SD Document Number -----------------------------------------------
    LOOP AT ls_mapped-customerreturn ASSIGNING <lfs_key>.
      rs_result-sales_order_number = <lfs_key>-CustomerReturn.
    ENDLOOP.

    IF rs_result-sales_order_number IS NOT INITIAL.
      add_success( EXPORTING iv_document_number  = rs_result-sales_order_number
                             iv_sf_header_id_ref = is_order-sf_header_id_ref
                   CHANGING  ct_error            = rs_result-errors ).
    ELSE.
      add_summary( EXPORTING iv_msgno            = '501'
                             iv_sf_header_id_ref = is_order-sf_header_id_ref
                   CHANGING  ct_error            = rs_result-errors ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
