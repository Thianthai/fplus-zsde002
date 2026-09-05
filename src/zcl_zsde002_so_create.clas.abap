CLASS zcl_zsde002_so_create DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      ty_order         TYPE ztsd_e002_order,
      tt_order_pricing TYPE STANDARD TABLE OF ztsd_e002_ordprc WITH EMPTY KEY,
      tt_item          TYPE STANDARD TABLE OF ztsd_e002_item   WITH EMPTY KEY,
      tt_item_pricing  TYPE STANDARD TABLE OF ztsd_e002_itmprc WITH EMPTY KEY,
      ty_param         TYPE zcl_zsde002_processor=>ty_param,
      tt_error         TYPE zcl_zsde002_processor=>tt_error.

    TYPES:
      BEGIN OF ty_result,
        sales_order_number TYPE ty_order-sales_order_number,
        errors             TYPE tt_error,
      END OF ty_result.

    "! สร้าง sales order 1 ใบจาก log row ที่ normalize แล้ว
    METHODS create
      IMPORTING is_order         TYPE ty_order
                it_order_pricing TYPE tt_order_pricing
                it_item          TYPE tt_item
                it_item_pricing  TYPE tt_item_pricing
                is_param         TYPE ty_param
      RETURNING VALUE(rs_result) TYPE ty_result.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES ty_amount   TYPE p LENGTH 11 DECIMALS 2.
    TYPES ty_quantity TYPE p LENGTH 13 DECIMALS 3.

    TYPES: BEGIN OF ty_cid_counter,
             prefix TYPE string,
             seq    TYPE i,
           END OF ty_cid_counter.

    DATA gt_cid_counter TYPE HASHED TABLE OF ty_cid_counter WITH UNIQUE KEY prefix.

    CONSTANTS gc_cid_header TYPE string    VALUE 'H01'.
    CONSTANTS gc_langu      TYPE spras     VALUE 'E'.

    "! %cid ที่ไม่ซ้ำกันทั้ง request — ของเดิมใช้ค่าคงที่ในลูปทำให้ RAP resolve ไม่ออก
    METHODS next_cid
      IMPORTING iv_prefix        TYPE string
      RETURNING VALUE(rv_result) TYPE string.

    METHODS to_date
      IMPORTING iv_value         TYPE clike
      RETURNING VALUE(rv_result) TYPE d.

    METHODS to_amount
      IMPORTING iv_value         TYPE clike
      RETURNING VALUE(rv_result) TYPE ty_amount.

    METHODS to_quantity
      IMPORTING iv_value         TYPE clike
      RETURNING VALUE(rv_result) TYPE ty_quantity.

ENDCLASS.



CLASS zcl_zsde002_so_create IMPLEMENTATION.

  METHOD next_cid.

    FIELD-SYMBOLS <lfs_counter> TYPE ty_cid_counter.

    READ TABLE gt_cid_counter ASSIGNING <lfs_counter>
         WITH TABLE KEY prefix = iv_prefix.

    IF sy-subrc <> 0.
      INSERT VALUE #( prefix = iv_prefix
                      seq    = 0 ) INTO TABLE gt_cid_counter ASSIGNING <lfs_counter>.
    ENDIF.

    <lfs_counter>-seq = <lfs_counter>-seq + 1.

    rv_result = |{ iv_prefix }{ <lfs_counter>-seq }|.

  ENDMETHOD.


  METHOD to_date.

    DATA(lv_internal) = zcl_zsde002_json=>to_internal_date( CONV #( iv_value ) ).

    IF strlen( lv_internal ) = 8.
      rv_result = lv_internal.
    ENDIF.

  ENDMETHOD.


  METHOD to_amount.

    IF iv_value IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        rv_result = CONV #( iv_value ).
      CATCH cx_sy_conversion_no_number.
        CLEAR rv_result.
    ENDTRY.

  ENDMETHOD.


  METHOD to_quantity.

    IF iv_value IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        rv_result = CONV #( iv_value ).
      CATCH cx_sy_conversion_no_number.
        CLEAR rv_result.
    ENDTRY.

  ENDMETHOD.


  METHOD create.

    DATA lt_header        TYPE TABLE FOR CREATE i_salesordertp.
    DATA lt_reference     TYPE TABLE FOR ACTION IMPORT i_salesordertp~createwithreference.
    DATA lt_partner       TYPE TABLE FOR CREATE i_salesordertp\_Partner.
    DATA lt_headerpricing TYPE TABLE FOR CREATE i_salesordertp\_PricingElement.
    DATA lt_headertext    TYPE TABLE FOR CREATE i_salesordertp\_Text.
    DATA lt_item          TYPE TABLE FOR CREATE i_salesordertp\_Item.
    DATA lt_itempricing   TYPE TABLE FOR CREATE i_salesorderitemtp\_ItemPricingElement.
    DATA lt_itemtext      TYPE TABLE FOR CREATE i_salesorderitemtp\_ItemText.

    DATA ls_partner       TYPE STRUCTURE FOR CREATE i_salesordertp\_Partner.
    DATA ls_headerpricing TYPE STRUCTURE FOR CREATE i_salesordertp\_PricingElement.
    DATA ls_headertext    TYPE STRUCTURE FOR CREATE i_salesordertp\_Text.
    DATA ls_item          TYPE STRUCTURE FOR CREATE i_salesordertp\_Item.
    DATA ls_itempricing   TYPE STRUCTURE FOR CREATE i_salesorderitemtp\_ItemPricingElement.
    DATA ls_itemtext      TYPE STRUCTURE FOR CREATE i_salesorderitemtp\_ItemText.

    CLEAR gt_cid_counter.

    " ---------- Header ----------
    " มี original_sales_document → สร้างผ่าน action เท่านั้น
    " ไม่มี → สร้างแบบปกติเท่านั้น
    " ทั้งสองทางใช้ %cid เดียวกัน child จึงผูกได้เหมือนกันไม่ว่าจะไปทางไหน
    IF is_order-original_sales_document IS NOT INITIAL.

      APPEND VALUE #( %cid   = gc_cid_header
                      %param = VALUE #( salesdocumenttype   = is_order-sales_order_type
                                        referencesddocument = is_order-original_sales_document )
                    ) TO lt_reference.

    ELSE.

      APPEND VALUE #( %cid                      = gc_cid_header
                      SalesOrderType            = is_order-sales_order_type
                      SalesOrganization         = is_order-sales_organization
                      DistributionChannel       = is_order-distribution_channel
                      OrganizationDivision      = is_order-division
                      SoldToParty               = is_order-sold_to_party
                      " EDI / ONLINE ยังไม่ได้กำหนดว่าดึงจาก field ไหน คงเงื่อนไขเดิมไว้ก่อน
                      PurchaseOrderByCustomer   = COND #( WHEN is_order-process_type IN is_param-lr_processtype_sfid
                                                          THEN is_order-customer_reference )
                      CustomerPurchaseOrderDate = to_date( is_order-customer_reference_date )
                      SalesOrderDate            = to_date( is_order-document_date )
                      RequestedDeliveryDate     = to_date( is_order-req_delivery_date )
                      ShippingCondition         = is_order-shipping_conditions
                      TransactionCurrency       = is_order-currency
                      CustomerPaymentTerms      = is_order-payment_term
                      SDDocumentReason          = COND #( WHEN is_order-tran_type IN is_param-lr_trantype_reason
                                                          THEN is_order-order_reason )
                    ) TO lt_header.

    ENDIF.

    " ---------- Header Partner ----------
    ls_partner-%cid_ref = gc_cid_header.

    IF is_order-ship_to_party IS NOT INITIAL.
      APPEND VALUE #( %cid                   = next_cid( `PA` )
                      PartnerFunctionForEdit = 'WE'
                      Customer               = is_order-ship_to_party ) TO ls_partner-%target.
    ENDIF.

    IF is_order-bill_to_party IS NOT INITIAL.
      APPEND VALUE #( %cid                   = next_cid( `PA` )
                      PartnerFunctionForEdit = 'RE'
                      Customer               = is_order-bill_to_party ) TO ls_partner-%target.
    ENDIF.

    IF is_order-payer IS NOT INITIAL.
      APPEND VALUE #( %cid                   = next_cid( `PA` )
                      PartnerFunctionForEdit = 'RG'
                      Customer               = is_order-payer ) TO ls_partner-%target.
    ENDIF.

    IF  is_order-stock_van IS NOT INITIAL
    AND is_order-process_type IN is_param-lr_processtype_stockvan.
      APPEND VALUE #( %cid                   = next_cid( `PA` )
                      PartnerFunctionForEdit = 'SB'          " <-- ยังไม่ยืนยัน ดูหมายเหตุ
                      Customer               = is_order-stock_van ) TO ls_partner-%target.
    ENDIF.

    IF ls_partner-%target IS NOT INITIAL.
      APPEND ls_partner TO lt_partner.
    ENDIF.

    " ---------- Header Pricing ----------
    ls_headerpricing-%cid_ref = gc_cid_header.

    LOOP AT it_order_pricing ASSIGNING FIELD-SYMBOL(<lfs_order_pricing>).
      CHECK <lfs_order_pricing>-condition_type IS NOT INITIAL.

      APPEND VALUE #( %cid                  = next_cid( `HP` )
                      ConditionType         = <lfs_order_pricing>-condition_type
                      ConditionRateAmount   = to_amount( <lfs_order_pricing>-condition_amount )
                      ConditionCurrency     = <lfs_order_pricing>-condition_currency
                      ConditionQuantity     = to_quantity( <lfs_order_pricing>-condition_pricing_unit )
                      ConditionQuantityUnit = <lfs_order_pricing>-condition_unit_of_measure
                    ) TO ls_headerpricing-%target.
    ENDLOOP.

    IF ls_headerpricing-%target IS NOT INITIAL.
      APPEND ls_headerpricing TO lt_headerpricing.
    ENDIF.

    " ---------- Header Text ----------
    ls_headertext-%cid_ref = gc_cid_header.

    APPEND VALUE #( %cid              = next_cid( `HT` )
                    LanguageForEdit   = gc_langu
                    LongTextIDForEdit = 'ZT01'
                    LongText          = COND #( WHEN is_order-process_type IN is_param-lr_processtype_zt01
                                                THEN is_order-payment_transaction_reference )
                  ) TO ls_headertext-%target.

    APPEND VALUE #( %cid              = next_cid( `HT` )
                    LanguageForEdit   = gc_langu
                    LongTextIDForEdit = 'ZT02'
                    LongText          = COND #( WHEN is_order-process_type IN is_param-lr_processtype_zt02
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
                    LongText          = COND #( WHEN is_order-order_reason IN is_param-lr_order_reason
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

    " ---------- Item ----------
    ls_item-%cid_ref = gc_cid_header.

    LOOP AT it_item ASSIGNING FIELD-SYMBOL(<lfs_item>).

      DATA(lv_item_cid) = next_cid( `IT` ).

      APPEND VALUE #( %cid                   = lv_item_cid
                      Product                = zcl_zsde002_validator=>to_internal_material( <lfs_item>-material_number )
                      MaterialByCustomer     = <lfs_item>-customer_material
                      SalesOrderItemCategory = <lfs_item>-item_category
                      RequestedQuantity      = to_quantity( <lfs_item>-requested_quantity )
                      RequestedQuantityUnit  = <lfs_item>-sales_unit
                      Plant                  = <lfs_item>-plant
                      StorageLocation        = COND #( WHEN is_order-process_type IN is_param-lr_processtype_sloc
                                                       THEN <lfs_item>-storage_location )
                      Batch                  = COND #( WHEN is_order-process_type IN is_param-lr_processtype_batch
                                                       THEN <lfs_item>-batch )
                      Route                  = <lfs_item>-route
                    ) TO ls_item-%target.

      " ---------- Item Pricing ----------
      CLEAR ls_itempricing.
      ls_itempricing-%cid_ref = lv_item_cid.

      LOOP AT it_item_pricing ASSIGNING FIELD-SYMBOL(<lfs_item_pricing>)
           WHERE item_uuid = <lfs_item>-item_uuid.

        CHECK <lfs_item_pricing>-condition_type IS NOT INITIAL.

        APPEND VALUE #( %cid                  = next_cid( `IP` )
                        ConditionType         = <lfs_item_pricing>-condition_type
                        ConditionRateAmount   = to_amount( <lfs_item_pricing>-condition_amount )
                        ConditionCurrency     = <lfs_item_pricing>-condition_currency
                        ConditionQuantity     = to_quantity( <lfs_item_pricing>-condition_pricing_unit )
                        ConditionQuantityUnit = <lfs_item_pricing>-condition_unit_of_measure
                      ) TO ls_itempricing-%target.
      ENDLOOP.

      IF ls_itempricing-%target IS NOT INITIAL.
        APPEND ls_itempricing TO lt_itempricing.
      ENDIF.

      " ---------- Item Text ----------
      CLEAR ls_itemtext.
      ls_itemtext-%cid_ref = lv_item_cid.

      APPEND VALUE #( %cid              = next_cid( `IX` )
                      LanguageForEdit   = gc_langu
                      LongTextIDForEdit = 'ZT05'
                      LongText          = <lfs_item>-sales_text ) TO ls_itemtext-%target.

      APPEND VALUE #( %cid              = next_cid( `IX` )
                      LanguageForEdit   = gc_langu
                      LongTextIDForEdit = 'ZT06'
                      LongText          = <lfs_item>-unit_text ) TO ls_itemtext-%target.

      APPEND VALUE #( %cid              = next_cid( `IX` )
                      LanguageForEdit   = gc_langu
                      LongTextIDForEdit = 'ZT07'
                      LongText          = <lfs_item>-promotion_id_text ) TO ls_itemtext-%target.

      APPEND VALUE #( %cid              = next_cid( `IX` )
                      LanguageForEdit   = gc_langu
                      LongTextIDForEdit = 'ZT09'
                      LongText          = COND #( WHEN is_order-process_type IN is_param-lr_processtype_sfid
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

    " ---------- Create ----------
    MODIFY ENTITIES OF i_salesordertp
      ENTITY SalesOrder
        EXECUTE createwithreference
          FIELDS ( SalesDocumentType
                   ReferenceSDDocument )
          WITH lt_reference

        CREATE FIELDS ( SalesOrderType
                        SalesOrganization
                        DistributionChannel
                        OrganizationDivision
                        SoldToParty
                        PurchaseOrderByCustomer
                        CustomerPurchaseOrderDate
                        SalesOrderDate
                        RequestedDeliveryDate
                        ShippingCondition
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
                   SalesOrderItemCategory
                   RequestedQuantity
                   RequestedQuantityUnit
                   Plant
                   StorageLocation
                   Batch
                   Route )
          WITH lt_item

      ENTITY SalesOrderItem
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

    " ---------- Message จาก modify ----------
    " ข้อความจาก RAP เป็น free text จึงใช้ message 000 แล้วใส่ข้อความลง msgtx ตรงๆ
    " ไม่ผ่าน message_text เพราะ placeholder ของ T100 ตัดที่ 50 ตัวอักษร
    LOOP AT ls_reported-salesorder INTO DATA(ls_reported_header) WHERE %msg IS BOUND.
      APPEND VALUE #( msgno            = '000'
                      msgty            = ls_reported_header-%msg->m_severity
                      msgtx            = ls_reported_header-%msg->if_message~get_text( )
                      sf_header_id_ref = is_order-sf_header_id_ref
                    ) TO rs_result-errors.
    ENDLOOP.

    LOOP AT ls_reported-salesorderitem INTO DATA(ls_reported_item) WHERE %msg IS BOUND.
      APPEND VALUE #( msgno            = '000'
                      msgty            = ls_reported_item-%msg->m_severity
                      msgtx            = ls_reported_item-%msg->if_message~get_text( )
                      sf_header_id_ref = is_order-sf_header_id_ref
                    ) TO rs_result-errors.
    ENDLOOP.

    " ล้มตั้งแต่ modify แล้วไม่ต้อง commit
    IF ls_failed IS NOT INITIAL.
      APPEND VALUE #( msgno            = '501'
                      msgty            = 'E'
                      msgtx            = zcl_zsde002_processor=>message_text(
                                           iv_msgno = '501'
                                           iv_v1    = |{ is_order-sf_header_id_ref }| )
                      sf_header_id_ref = is_order-sf_header_id_ref
                    ) TO rs_result-errors.
      RETURN.
    ENDIF.

    " ---------- Commit ----------
    COMMIT ENTITIES BEGIN
      RESPONSE OF i_salesordertp
      FAILED   DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

    IF ls_commit_failed-salesorder IS INITIAL.
      LOOP AT ls_mapped-salesorder ASSIGNING FIELD-SYMBOL(<lfs_key>).
        CONVERT KEY OF i_salesordertp FROM <lfs_key>-%pid TO <lfs_key>-%key.
      ENDLOOP.
    ENDIF.

    COMMIT ENTITIES END.

    LOOP AT ls_commit_reported-salesorder INTO DATA(ls_commit_msg) WHERE %msg IS BOUND.
      APPEND VALUE #( msgno            = '000'
                      msgty            = ls_commit_msg-%msg->m_severity
                      msgtx            = ls_commit_msg-%msg->if_message~get_text( )
                      sf_header_id_ref = is_order-sf_header_id_ref
                    ) TO rs_result-errors.
    ENDLOOP.

    IF ls_commit_failed IS NOT INITIAL.
      APPEND VALUE #( msgno            = '502'
                      msgty            = 'E'
                      msgtx            = zcl_zsde002_processor=>message_text(
                                           iv_msgno = '502'
                                           iv_v1    = |{ is_order-sf_header_id_ref }| )
                      sf_header_id_ref = is_order-sf_header_id_ref
                    ) TO rs_result-errors.
      RETURN.
    ENDIF.

    " ---------- Sales Order Number ----------
    LOOP AT ls_mapped-salesorder ASSIGNING <lfs_key>.
      rs_result-sales_order_number = <lfs_key>-SalesOrder.
    ENDLOOP.

    IF rs_result-sales_order_number IS NOT INITIAL.
      APPEND VALUE #( msgno            = '500'
                      msgty            = 'S'
                      msgtx            = zcl_zsde002_processor=>message_text(
                                           iv_msgno = '500'
                                           iv_msgty = 'S'
                                           iv_v1    = |{ rs_result-sales_order_number }| )
                      sf_header_id_ref = is_order-sf_header_id_ref
                    ) TO rs_result-errors.
    ELSE.
      APPEND VALUE #( msgno            = '501'
                      msgty            = 'E'
                      msgtx            = zcl_zsde002_processor=>message_text(
                                           iv_msgno = '501'
                                           iv_v1    = |{ is_order-sf_header_id_ref }| )
                      sf_header_id_ref = is_order-sf_header_id_ref
                    ) TO rs_result-errors.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
