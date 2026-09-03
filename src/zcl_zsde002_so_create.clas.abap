CLASS zcl_zsde002_so_create DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_pricing,
             conditiontype          TYPE string,
             conditionamount        TYPE p LENGTH 11 DECIMALS 2,
             conditioncurrency      TYPE string,
             conditionpricingunit   TYPE p LENGTH 5 DECIMALS 0,
             conditionunitofmeasure TYPE string,
           END OF ty_pricing,
           tt_pricing TYPE STANDARD TABLE OF ty_pricing WITH EMPTY KEY.

    TYPES: BEGIN OF ty_item,
             " Item Data
             item              TYPE string,
             materialnumber    TYPE string,
             customermaterial  TYPE string,
             itemcategory      TYPE string,
             requestedquantity TYPE string,
             salesunit         TYPE string,
             plant             TYPE string,
             storagelocation   TYPE string,
             mattaxclass       TYPE string,
             salestext         TYPE string,
             unittext          TYPE string,
             promotionidtext   TYPE string,
             batch             TYPE string,
             route             TYPE string,
             sfitemidref       TYPE string,
             " Item Pricing Data
             pricing           TYPE tt_pricing,
           END OF ty_item,
           tt_item TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

    TYPES: BEGIN OF ty_order,
             " Header Data
             sfheaderidref               TYPE string,
             salesordertempid            TYPE string,
             processtype                 TYPE string,
             trantype                    TYPE string,
             salesordertype              TYPE string,
             salesorganization           TYPE string,
             distributionchannel         TYPE string,
             division                    TYPE string,
             soldtoparty                 TYPE string,
             customerbranch              TYPE string,
             shiptoparty                 TYPE string,
             billtoparty                 TYPE string,
             payer                       TYPE string,
             stockvan                    TYPE string,
             customerreference           TYPE string,
             customerreferencedate       TYPE string,
             documentdate                TYPE string,
             reqdeliverydate             TYPE string,
             shippingconditions          TYPE string,
             paymenttransactionreference TYPE string,
             taxdocumentno               TYPE string,
             relateddocumentreference    TYPE string,
             currency                    TYPE string,
             paymentterm                 TYPE string,
             originalsalesdocument       TYPE string,
             orderreason                 TYPE string,
             orderreasontext             TYPE string,
             customerpo                  TYPE string,
             " Header Pricing Data
             pricing                     TYPE tt_pricing,
             " Item Data
             item                        TYPE tt_item,
           END OF ty_order.

    TYPES: BEGIN OF ty_message,
             status  TYPE c LENGTH 1,
             message TYPE string,
           END OF ty_message,
           tt_message TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY.

    TYPES: BEGIN OF ty_sys_message, " For store system messages. Do not change this structure.
             severity TYPE c LENGTH 1,
             area     TYPE string,
             text     TYPE string,
           END OF ty_sys_message,
           tt_sys_message TYPE STANDARD TABLE OF ty_sys_message WITH EMPTY KEY.

    TYPES: BEGIN OF ty_result,
*             requestuuid      TYPE sysuuid_x16, " Gnerated UUID
             salesordernumber  TYPE string,
             documenttype      TYPE string,
             customerreference TYPE string,
             sfheaderidref     TYPE string,
             processingdate    TYPE string,
             processingtime    TYPE string,
             message           TYPE tt_message,
             system_message    TYPE tt_sys_message, " System messages
           END OF ty_result,
           tt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.

    CLASS-METHODS create
      IMPORTING is_request       TYPE ty_order
                io_param         TYPE REF TO zcl_param
      RETURNING VALUE(rs_result) TYPE ty_result.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES: tt_partner     TYPE TABLE FOR CREATE i_salesordertp\_Partner.
    TYPES: ty_partners    TYPE LINE OF tt_partner.
    TYPES: ty_partner     TYPE LINE OF ty_partners-%target.

    TYPES: tt_headertext  TYPE TABLE FOR CREATE i_salesordertp\_Text.
    TYPES: ty_headertexts TYPE LINE OF tt_headertext.
    TYPES: ty_headertext  TYPE LINE OF ty_headertexts-%target.

    TYPES: tt_itemtext    TYPE TABLE FOR CREATE i_salesorderitemtp\_ItemText.
    TYPES: ty_itemtexts   TYPE LINE OF tt_itemtext.
    TYPES: ty_itemtext    TYPE LINE OF ty_itemtexts-%target.

    CONSTANTS:
      cv_langu TYPE ty_headertext-LanguageForEdit VALUE 'E'.

    CLASS-DATA:
      lo_param                TYPE REF TO zcl_param,
      lr_processtype_stockvan TYPE RANGE OF ty_order-processtype,
      lr_processtype_sfid     TYPE RANGE OF ty_order-processtype,
      lr_processtype_edi      TYPE RANGE OF ty_order-processtype,
      lr_processtype_online   TYPE RANGE OF ty_order-processtype,
      lr_processtype_zt01     TYPE RANGE OF ty_order-processtype,
      lr_processtype_zt02     TYPE RANGE OF ty_order-processtype,
      lr_processtype_zt04     TYPE RANGE OF I_SalesDocument-SDDocumentReason,
      lr_processtype_zt09     TYPE RANGE OF ty_order-processtype,
      lr_processtype_sloc     TYPE RANGE OF ty_order-processtype,
      lr_processtype_batch    TYPE RANGE OF ty_order-processtype,
      lr_trantype_reason      TYPE RANGE OF ty_order-trantype.

    CLASS-METHODS to_system_date
      IMPORTING
        iv_iso         TYPE string
      RETURNING
        value(rv_date) TYPE datum.

    CLASS-METHODS add_message
      IMPORTING io_msg    TYPE REF TO if_abap_behv_message
                iv_area   TYPE string
      CHANGING  cs_result TYPE ty_result.

    CLASS-METHODS get_error
      IMPORTING it_sys_message TYPE tt_sys_message
                iv_default     TYPE string
      RETURNING VALUE(rv_text) TYPE string.

ENDCLASS.



CLASS zcl_zsde002_so_create IMPLEMENTATION.

  METHOD create.

    DATA lt_header        TYPE TABLE FOR CREATE i_salesordertp.
    DATA lt_partner       TYPE TABLE FOR CREATE i_salesordertp\_Partner.
    DATA lt_headerpricing TYPE TABLE FOR CREATE i_salesordertp\_PricingElement.
    DATA lt_headertext    TYPE TABLE FOR CREATE i_salesordertp\_Text.
    DATA lt_item          TYPE TABLE FOR CREATE i_salesordertp\_Item.
    DATA lt_itempricing   TYPE TABLE FOR CREATE i_salesorderitemtp\_ItemPricingElement.
    DATA lt_itemtext      TYPE TABLE FOR CREATE i_salesorderitemtp\_ItemText.
    DATA lt_reference     TYPE TABLE FOR ACTION IMPORT i_salesordertp~createwithreference.

    DATA lv_item_cid(3)   TYPE n.

   " Get Constant Parameters
*    zcl_zsde002_http=>get_constant_param( EXPORTING io_param = io_param ).

    " Generate UUID
*    TRY.
*        rs_result-requestuuid = cl_system_uuid=>create_uuid_x16_static( ).
*      CATCH cx_uuid_error.
*        CLEAR rs_result-requestuuid.
*    ENDTRY.

    " Prepare Header
    APPEND INITIAL LINE TO lt_header ASSIGNING FIELD-SYMBOL(<lfs_header>).
    IF <lfs_header> IS ASSIGNED.
      <lfs_header>-%cid                      = 'H0O1'.
*      ProcessType
*      TranType
      <lfs_header>-SalesOrderType            = is_request-salesordertype.
      <lfs_header>-SalesOrganization         = is_request-salesorganization.
      <lfs_header>-DistributionChannel       = is_request-distributionchannel.
      <lfs_header>-OrganizationDivision      = is_request-division.
      <lfs_header>-SoldToParty               = |{ is_request-soldtoparty ALPHA = IN }|.
*      CustomerBranch = is_request-customerbranch

      IF is_request-processtype IN lr_processtype_sfid.
        <lfs_header>-PurchaseOrderByCustomer = is_request-customerreference.
      ELSEIF is_request-processtype IN lr_processtype_edi.

      ELSEIF is_request-processtype IN lr_processtype_online.

      ENDIF.

      <lfs_header>-CustomerPurchaseOrderDate = to_system_date( is_request-customerreferencedate ).
      <lfs_header>-SalesOrderDate            = to_system_date( is_request-documentdate ).
      <lfs_header>-RequestedDeliveryDate     = to_system_date( is_request-reqdeliverydate ).
      <lfs_header>-ShippingCondition         = is_request-shippingconditions.
      <lfs_header>-TransactionCurrency       = is_request-currency.
      <lfs_header>-CustomerPaymentTerms      = is_request-paymentterm.
*      ReferenceSDDocument = is_request-originalsalesdocument

      IF is_request-trantype = 'R'.
        <lfs_header>-SDDocumentReason        = is_request-orderreason.
      ENDIF.

      " Prepare Header Reference SD Document
      IF is_request-originalsalesdocument IS NOT INITIAL.
        APPEND VALUE #( %cid   = <lfs_header>-%cid
                        %param = VALUE #( salesdocumenttype   = is_request-salesordertype
                                          referencesddocument = is_request-originalsalesdocument )
                      ) TO lt_reference.
      ENDIF.

      " Prepare Header Partner
      APPEND INITIAL LINE TO lt_partner ASSIGNING FIELD-SYMBOL(<lfs_partners>).
      IF <lfs_partners> IS ASSIGNED.
        <lfs_partners>-%cid_ref   = <lfs_header>-%cid.
        <lfs_partners>-salesorder = space.

        APPEND VALUE #( %cid            = 'P001'
                        PartnerFunction = 'SH'
                        Customer        = |{ is_request-shiptoparty ALPHA = IN }|
                      ) TO <lfs_partners>-%target.

        APPEND VALUE #( %cid            = 'P002'
                        PartnerFunction = 'BP'
                        Customer        = |{ is_request-billtoparty ALPHA = IN }|
                      ) TO <lfs_partners>-%target.

        APPEND VALUE #( %cid            = 'P003'
                        PartnerFunction = 'PY'
                        Customer        = |{ is_request-payer ALPHA = IN }|
                      ) TO <lfs_partners>-%target.

        IF is_request-processtype IN lr_processtype_stockvan.
          APPEND VALUE #( %cid            = 'P004'
                          PartnerFunction = 'SB'
                          Customer        = |{ is_request-stockvan ALPHA = IN }|
                        ) TO <lfs_partners>-%target.
        ENDIF.
      ENDIF.

      " Prepare Header Pricing Element
      APPEND INITIAL LINE TO lt_headerpricing ASSIGNING FIELD-SYMBOL(<lfs_headerpricings>).
      IF <lfs_headerpricings> IS ASSIGNED.
        <lfs_headerpricings>-%cid_ref   = <lfs_header>-%cid.
        <lfs_headerpricings>-SalesOrder = space.

        LOOP AT is_request-pricing ASSIGNING FIELD-SYMBOL(<lfs_pricing>).
          APPEND VALUE #( %cid                           = 'HDPRELM01'
                          ConditionType                  = <lfs_pricing>-conditiontype
                          ConditionRateAmount            = <lfs_pricing>-conditionamount
                          ConditionCurrency              = <lfs_pricing>-conditioncurrency
                          ConditionQuantity              = <lfs_pricing>-conditionpricingunit
                          ConditionQuantityUnit          = <lfs_pricing>-conditionunitofmeasure
                          %control-ConditionType         = if_abap_behv=>mk-on
                          %control-ConditionRateAmount   = if_abap_behv=>mk-on
                          %control-ConditionCurrency     = if_abap_behv=>mk-on
                          %control-ConditionQuantity     = if_abap_behv=>mk-on
                          %control-ConditionQuantityUnit = if_abap_behv=>mk-on
                        ) TO <lfs_headerpricings>-%target.
        ENDLOOP.
      ENDIF.

      " Prepare Header Text
      APPEND INITIAL LINE TO lt_headertext ASSIGNING FIELD-SYMBOL(<lfs_headertexts>).
      IF <lfs_headertexts> IS ASSIGNED.
        <lfs_headertexts>-%cid_ref   = <lfs_header>-%cid.
        <lfs_headertexts>-salesorder = space.

        " PaymentTransactionReference
        APPEND VALUE #( %cid              = 'HT001'
                        LanguageForEdit   = cv_langu
                        LongTextIDForEdit = 'ZT01'
                        LongText          = COND #( WHEN is_request-processtype IN lr_processtype_zt01
                                                    THEN is_request-paymenttransactionreference ELSE space )
                      ) TO <lfs_headertexts>-%target.

        " TaxDocumentNo
        APPEND VALUE #( %cid              = 'HT002'
                        LanguageForEdit   = cv_langu
                        LongTextIDForEdit = 'ZT02'
                        LongText          = COND #( WHEN is_request-processtype IN lr_processtype_zt02
                                                    THEN is_request-taxdocumentno ELSE space )
                      ) TO <lfs_headertexts>-%target.

        " RelatedDocumentReference
        APPEND VALUE #( %cid              = 'HT003'
                        LanguageForEdit   = cv_langu
                        LongTextIDForEdit = 'ZT03'
                        LongText          = is_request-relateddocumentreference
                      ) TO <lfs_headertexts>-%target.

        " OrderReasonText
        APPEND VALUE #( %cid              = 'HT004'
                        LanguageForEdit   = cv_langu
                        LongTextIDForEdit = 'ZT04'
                        LongText          = COND #( WHEN is_request-processtype IN lr_processtype_zt04
                                                    THEN is_request-orderreasontext ELSE space )
                      ) TO <lfs_headertexts>-%target.

        " SFHeaderIdRef
        APPEND VALUE #( %cid              = 'HT005'
                        LanguageForEdit   = cv_langu
                        LongTextIDForEdit = 'ZT08'
                        LongText          = is_request-sfheaderidref
                      ) TO <lfs_headertexts>-%target.

        DELETE <lfs_headertexts>-%target WHERE LongText IS INITIAL.
      ENDIF.

      " Prepare Item
      APPEND INITIAL LINE TO lt_item ASSIGNING FIELD-SYMBOL(<lfs_items>).
      IF <lfs_items> IS ASSIGNED.
        <lfs_items>-%cid_ref   = <lfs_header>-%cid.
        <lfs_items>-SalesOrder = space.

        LOOP AT is_request-item INTO DATA(ls_request_item).
          lv_item_cid = lv_item_cid + 1.

          APPEND INITIAL LINE TO <lfs_items>-%target ASSIGNING FIELD-SYMBOL(<lfs_item>).
          IF <lfs_item> IS ASSIGNED.
            <lfs_item>-%cid                   = |I{ lv_item_cid }|.
            <lfs_item>-Product                = ls_request_item-materialnumber.
            <lfs_item>-MaterialByCustomer     = ls_request_item-customermaterial.
            <lfs_item>-SalesOrderItemCategory = ls_request_item-itemcategory.
            <lfs_item>-RequestedQuantity      = ls_request_item-requestedquantity.
            <lfs_item>-RequestedQuantityUnit  = ls_request_item-salesunit.
            <lfs_item>-Plant                  = ls_request_item-plant.
            <lfs_item>-StorageLocation        = COND #( WHEN is_request-processtype IN lr_processtype_sloc
                                                        THEN ls_request_item-storagelocation ELSE space ).
*            ProductTaxClassification1 "! Update via Custom Logic
            <lfs_item>-Batch                  = COND #( WHEN is_request-processtype IN lr_processtype_batch
                                                        THEN ls_request_item-batch ELSE space ).
            <lfs_item>-Route                  = ls_request_item-route.

            " Prepare Item Pricing Element
            LOOP AT ls_request_item-pricing INTO DATA(ls_item_pricing).
              APPEND INITIAL LINE TO lt_itempricing ASSIGNING FIELD-SYMBOL(<lfs_itempricings>).
              IF <lfs_itempricings> IS ASSIGNED.
                <lfs_itempricings>-%cid_ref       = <lfs_item>-%cid.
                <lfs_itempricings>-salesorder     = space.
                <lfs_itempricings>-salesorderitem = space.

                APPEND VALUE #(  %cid                           = |ITPRELM{ lv_item_cid }|
                                 ConditionType                  = ls_item_pricing-conditiontype
                                 ConditionRateAmount            = ls_item_pricing-conditionamount
                                 ConditionCurrency              = ls_item_pricing-conditioncurrency
                                 ConditionQuantity              = ls_item_pricing-conditionpricingunit
                                 ConditionQuantityUnit          = ls_item_pricing-conditionunitofmeasure
                                 %control-ConditionType         = if_abap_behv=>mk-on
                                 %control-ConditionRateAmount   = if_abap_behv=>mk-on
                                 %control-ConditionCurrency     = if_abap_behv=>mk-on
                                 %control-ConditionQuantity     = if_abap_behv=>mk-on
                                 %control-ConditionQuantityUnit = if_abap_behv=>mk-on
                              ) TO <lfs_itempricings>-%target.

                UNASSIGN <lfs_itempricings>.
              ENDIF.
            ENDLOOP.

            " Prepare Item Text
            APPEND INITIAL LINE TO lt_itemtext ASSIGNING FIELD-SYMBOL(<lfs_itemtexts>).
            IF <lfs_itemtexts> IS ASSIGNED.
              <lfs_itemtexts>-%cid_ref       = <lfs_item>-%cid.
              <lfs_itemtexts>-salesorder     = space.
              <lfs_itemtexts>-salesorderitem = space.

              " SalesText
              APPEND VALUE #( %cid              = |IT{ lv_item_cid }|
                              LanguageForEdit   = cv_langu
                              LongTextIDForEdit = 'ZT05'
                              LongText          = ls_request_item-salestext
                            ) TO <lfs_itemtexts>-%target.

              " UnitText
              APPEND VALUE #( %cid              = |IT{ lv_item_cid }|
                              LanguageForEdit   = cv_langu
                              LongTextIDForEdit = 'ZT06'
                              LongText          = ls_request_item-unittext
                            ) TO <lfs_itemtexts>-%target.

              " PromotionIDText
              APPEND VALUE #( %cid              = |IT{ lv_item_cid }|
                              LanguageForEdit   = cv_langu
                              LongTextIDForEdit = 'ZT07'
                              LongText          = ls_request_item-promotionidtext
                            ) TO <lfs_itemtexts>-%target.

              " SFItemIdRef
              IF is_request-processtype IN lr_processtype_zt09.
                APPEND VALUE #( %cid              = |IT{ lv_item_cid }|
                                LanguageForEdit   = cv_langu
                                LongTextIDForEdit = 'ZT07'
                                LongText          = ls_request_item-sfitemidref
                              ) TO <lfs_itemtexts>-%target.
              ENDIF.

              DELETE <lfs_itemtexts>-%target WHERE LongText IS INITIAL.

              UNASSIGN <lfs_itemtexts>.
            ENDIF.

            UNASSIGN <lfs_item>.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.

   " Create Sales Order with Reference
    IF is_request-originalsalesdocument IS NOT INITIAL.
      MODIFY ENTITIES OF i_salesordertp
      ENTITY salesorder
      EXECUTE createwithreference
      FIELDS ( salesdocumenttype
               referencesddocument )
      WITH VALUE #( ( %cid   = 'H001'
                      %param = VALUE #( salesdocumenttype   = is_request-salesordertype
                                        referencesddocument = is_request-originalsalesdocument ) ) )
      MAPPED DATA(ls_mapped_ref)
      FAILED DATA(ls_failed_ref)
      REPORTED DATA(ls_reported_ref).
    ENDIF.

    " Create Sale Order
    MODIFY ENTITIES OF i_salesordertp PRIVILEGED
      ENTITY salesorder
      CREATE FIELDS (
        SalesOrderType
        SalesOrganization
        DistributionChannel
        OrganizationDivision
        SoldToParty
*        CustomerBranch "! Not supported for version 2608
        PurchaseOrderByCustomer
        CustomerPurchaseOrderDate
        SalesOrderDate
        RequestedDeliveryDate
        ShippingCondition
        TransactionCurrency
        CustomerPaymentTerms
        SDDocumentReason
      )
      WITH lt_header

        CREATE BY \_partner
        FIELDS (
          personnel
          partnerfunctionforedit
        )
        WITH lt_partner

        CREATE BY \_pricingelement
        FIELDS (
          ConditionType
          ConditionRateAmount
          ConditionCurrency
          ConditionQuantity
          ConditionQuantityUnit
        )
        WITH lt_headerpricing

        CREATE BY \_text
        FIELDS (
          languageforedit
          longtextidforedit
          longtext
        )
        WITH lt_headertext

        CREATE BY \_Item
        FIELDS (
          Product
          MaterialByCustomer
          SalesOrderItemCategory
          RequestedQuantity
          RequestedQuantityUnit
          Plant
          StorageLocation
*         TaxClassification1
          Batch
          Route
        )
        WITH lt_item

      ENTITY salesorderitem
        CREATE BY \_ItemPricingElement
        FIELDS
        (
          ConditionType
          ConditionRateAmount
          ConditionCurrency
          ConditionQuantity
          ConditionQuantityUnit
        )
        WITH lt_itempricing

        CREATE BY \_itemtext
        FIELDS (
          languageforedit
          longtextidforedit
          longtext
        )
        WITH lt_itemtext

    MAPPED   DATA(ls_mapped)
    FAILED   DATA(ls_failed)
    REPORTED DATA(ls_reported).

    " Merge mapped/failed/reported
    APPEND LINES OF ls_mapped_ref-salesorder   TO ls_mapped-salesorder.
    APPEND LINES OF ls_failed_ref-salesorder   TO ls_failed-salesorder.
    APPEND LINES OF ls_reported_ref-salesorder TO ls_reported-salesorder.

    " Get message
    LOOP AT ls_reported-salesorder INTO DATA(ls_reported_header) WHERE %msg IS BOUND.
      add_message( EXPORTING io_msg    = ls_reported_header-%msg
                             iv_area   = 'HEADER'
                    CHANGING cs_result = rs_result ).
    ENDLOOP.

    LOOP AT ls_reported-salesorderitem INTO DATA(ls_reported_item) WHERE %msg IS BOUND.
      add_message( EXPORTING io_msg    = ls_reported_item-%msg
                             iv_area   = 'ITEM'
                    CHANGING cs_result = rs_result ).
    ENDLOOP.

    " Commit entity
    COMMIT ENTITIES BEGIN
      RESPONSE OF i_salesordertp
      FAILED   DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

    " Get Sales Order Number
    IF ls_commit_failed-salesorder IS INITIAL.
      LOOP AT ls_mapped-salesorder ASSIGNING FIELD-SYMBOL(<ls_key>).
        CONVERT KEY OF i_salesordertp FROM <ls_key>-%pid TO <ls_key>-%key.
      ENDLOOP.
    ENDIF.

    COMMIT ENTITIES END.

    " Get commit message
    LOOP AT ls_commit_reported-salesorder INTO DATA(ls_commit_reported_header) WHERE %msg IS BOUND.
      add_message( EXPORTING io_msg    = ls_commit_reported_header-%msg
                             iv_area   = 'COMMIT_HEADER'
                   CHANGING  cs_result = rs_result ).
    ENDLOOP.

    LOOP AT ls_commit_reported-salesorderitem INTO DATA(ls_commit_reported_item) WHERE %msg IS BOUND.
      add_message( EXPORTING io_msg    = ls_commit_reported_item-%msg
                             iv_area   = 'COMMIT_ITEM'
                   CHANGING  cs_result = rs_result ).
    ENDLOOP.

    " Return key field
    rs_result-documenttype      = is_request-salesordertype.
    rs_result-customerreference = is_request-customerreference.
    rs_result-sfheaderidref     = is_request-sfheaderidref.
    rs_result-processingdate    = cl_abap_context_info=>get_system_date( ).
    rs_result-processingtime    = cl_abap_context_info=>get_system_time( ).

    " Return error message
    IF ls_commit_failed IS NOT INITIAL.
      APPEND VALUE #( status  = 'E'
                      message = get_error( it_sys_message = rs_result-system_message
                                           iv_default     = 'Create sales order failed' )
                    ) TO rs_result-message.
      RETURN.
    ENDIF.

    " Return success message
    LOOP AT ls_mapped-salesorder ASSIGNING <ls_key>.
      rs_result-salesordernumber = <ls_key>-SalesOrder.
    ENDLOOP.

    APPEND VALUE #( status  = 'S'
                    message = |Sales order { rs_result-salesordernumber } created|
                  ) TO rs_result-message.

  ENDMETHOD.

  METHOD to_system_date.

    IF strlen( iv_iso ) = 10.
      rv_date = |{ iv_iso+0(4) }{ iv_iso+5(2) }{ iv_iso+8(2) }|.
    ENDIF.

  ENDMETHOD.

  METHOD add_message.

    APPEND INITIAL LINE TO cs_result-system_message ASSIGNING FIELD-SYMBOL(<lfs_message>).
    <lfs_message>-severity = io_msg->m_severity.
    <lfs_message>-area     = iv_area.
    <lfs_message>-text     = io_msg->if_message~get_text( ).

  ENDMETHOD.

  METHOD get_error.

    LOOP AT it_sys_message INTO DATA(ls_sys_message) WHERE severity = 'E'.
      rv_text = |{ iv_default }: { ls_sys_message-text }|.
      EXIT.
    ENDLOOP.

    IF rv_text IS INITIAL.
      rv_text = iv_default.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
