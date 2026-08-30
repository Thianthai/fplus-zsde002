CLASS zcl_zsde002_handler DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .

    TYPES:
      tt_order       TYPE STANDARD TABLE OF zcl_zsde002_so_create=>ty_order   WITH EMPTY KEY,
      tt_item        TYPE STANDARD TABLE OF zcl_zsde002_so_create=>ty_item    WITH EMPTY KEY,
      tt_pricing     TYPE STANDARD TABLE OF zcl_zsde002_so_create=>ty_pricing WITH EMPTY KEY,
      ty_processtype TYPE zcl_zsde002_so_create=>ty_order-processtype,
      ty_trantype    TYPE zcl_zsde002_so_create=>ty_order-trantype.

    " JSON structure
    TYPES: BEGIN OF ty_order_response,
             salesordernumber  TYPE string,
             documenttype      TYPE string,
             customerreference TYPE string,
             sfheaderidref     TYPE string,
             processingdate    TYPE string,
             processingtime    TYPE string,
             message           TYPE zcl_zsde002_so_create=>tt_message,
           END OF ty_order_response,
           tt_order_response TYPE STANDARD TABLE OF ty_order_response WITH EMPTY KEY.

    TYPES: BEGIN OF ty_metadata,
             requestid TYPE string,
             order     TYPE tt_order,
           END OF ty_metadata.

    TYPES: BEGIN OF ty_deep_request,
             requestid TYPE string,
             order     TYPE tt_order, " Request data
           END OF ty_deep_request.

    TYPES: BEGIN OF ty_deep_response,
             requeststatus  TYPE c LENGTH 1,
             requestmessage TYPE string,
             order          TYPE tt_order_response,
           END OF ty_deep_response.

    TYPES: BEGIN OF ty_http_error,
             status  TYPE c LENGTH 1,
             message TYPE string,
           END OF ty_http_error.

    CLASS-METHODS get_constant_param
      IMPORTING io_param    TYPE REF TO zcl_param OPTIONAL
      CHANGING  cs_response TYPE ty_deep_response OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-DATA:
      lo_param                TYPE REF TO zcl_param,
      lr_processtype          TYPE RANGE OF ty_processtype,
      lr_processtype_stockvan TYPE RANGE OF ty_processtype,
      lr_processtype_zt01     TYPE RANGE OF ty_processtype,
      lr_processtype_zt02     TYPE RANGE OF ty_processtype,
      lr_trantype_reason      TYPE RANGE OF ty_trantype,
      lr_order_reason         TYPE RANGE OF I_SalesDocument-SDDocumentReason.

    CLASS-DATA:
      lr_processtype_sfid     TYPE RANGE OF ty_processtype,
      lr_processtype_edi      TYPE RANGE OF ty_processtype,
      lr_processtype_online   TYPE RANGE OF ty_processtype,
      lr_processtype_zt09     TYPE RANGE OF ty_processtype,
      lr_processtype_sloc     TYPE RANGE OF ty_processtype,
      lr_processtype_batch    TYPE RANGE OF ty_processtype.

    CLASS-METHODS validate_data
      IMPORTING is_request  TYPE ty_deep_request
      EXPORTING es_response TYPE ty_deep_response.

    CLASS-METHODS create_sales_order
      IMPORTING is_request       TYPE ty_deep_request
      EXPORTING es_response      TYPE ty_deep_response
                ev_total_success TYPE i
                ev_total_error   TYPE i.

    CLASS-METHODS to_json_format
      IMPORTING is_data        TYPE any
      RETURNING VALUE(rv_json) TYPE string.

    CLASS-METHODS get_current_date
      RETURNING VALUE(rv_date) TYPE string.

    CLASS-METHODS get_current_time
      RETURNING VALUE(rv_time) TYPE string.

    METHODS handle_get
      CHANGING co_http_response TYPE REF TO if_web_http_response.

    METHODS handle_post
      IMPORTING io_http_request  TYPE REF TO if_web_http_request
      CHANGING  co_http_response TYPE REF TO if_web_http_response.

    METHODS force_response
      CHANGING
        cs_response      TYPE zcl_zsde002_handler=>ty_deep_response
        co_http_response TYPE REF TO if_web_http_response.

ENDCLASS.



CLASS zcl_zsde002_handler IMPLEMENTATION.

  METHOD if_http_service_extension~handle_request.

    CASE request->get_method( ).
      WHEN 'GET'.
        handle_get( CHANGING co_http_response = response ).

      WHEN 'POST'.
        handle_post( EXPORTING io_http_request  = request
                     CHANGING  co_http_response = response ).

    ENDCASE.

  ENDMETHOD.

  METHOD get_constant_param.

    IF io_param IS SUPPLIED.
      lo_param = io_param.
    ELSE.
      lo_param = NEW #( iv_company_code = '1000'
                        iv_module_id    = 'SD' ).
    ENDIF.

    TRY.
        lo_param->get_range( EXPORTING iv_app_id     = 'ZSDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'CASH_VAN_SALES'
                             IMPORTING et_range      = lr_processtype_stockvan ).

        lo_param->get_range( EXPORTING iv_app_id     = 'ZSDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'SFID'
                             IMPORTING et_range      = lr_processtype_sfid ).

        lo_param->get_range( EXPORTING iv_app_id     = 'ZSDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'EDI'
                             IMPORTING et_range      = lr_processtype_edi ).

        lo_param->get_range( EXPORTING iv_app_id     = 'ZSDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'ONLINE'
                             IMPORTING et_range      = lr_processtype_online ).

        lo_param->get_range( EXPORTING iv_app_id     = 'ZSDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'ZT01'
                             IMPORTING et_range      = lr_processtype_zt01 ).

        lo_param->get_range( EXPORTING iv_app_id     = 'ZSDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'ZT02'
                             IMPORTING et_range      = lr_processtype_zt02 ).

        lo_param->get_range( EXPORTING iv_app_id     = 'ZSDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'ZT09'
                             IMPORTING et_range      = lr_processtype_zt09 ).

        lo_param->get_range( EXPORTING iv_app_id     = 'ZSDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'SLOC'
                             IMPORTING et_range      = lr_processtype_sloc ).

        lo_param->get_range( EXPORTING iv_app_id     = 'ZSDE002'
                                       iv_param_name = 'PROCESS_TYPE'
                                       iv_param_ext  = 'BATCH'
                             IMPORTING et_range      = lr_processtype_batch ).

        lo_param->get_range( EXPORTING iv_app_id     = 'ZSDE002'
                                       iv_param_name = 'TRAN_TYPE'
                                       iv_param_ext  = 'REASON'
                             IMPORTING et_range      = lr_trantype_reason ).

        lo_param->get_range( EXPORTING iv_app_id     = 'ZSDE002'
                                       iv_param_name = 'ORDER_REASON'
                                       iv_param_ext  = 'ZT04'
                             IMPORTING et_range      = lr_order_reason ).

      CATCH zcx_param INTO DATA(lcx_param).
        IF cs_response IS SUPPLIED.
          cs_response-requeststatus  = 'E'.
          cs_response-requestmessage = |ERROR ({ lcx_param->gv_reason }): { lcx_param->get_text( ) }|.
        ENDIF.
        RETURN.
    ENDTRY.

  ENDMETHOD.

  METHOD validate_data.

    TYPES:
      BEGIN OF ty_mandatory_field,
        " Header
        salesordertempid    TYPE string,
        processtype         TYPE string,
        trantype            TYPE string,
        salesdocumenttype   TYPE string,
        salesorganization   TYPE string,
        distributionchannel TYPE string,
        division            TYPE string,
        soldtoparty         TYPE string,
        shiptoparty         TYPE string,
        billtoparty         TYPE string,
        payer               TYPE string,
        customerreference   TYPE string,
        documentdate        TYPE string,
        shippingconditions  TYPE string,
        sfheaderidref       TYPE string,
        " Item
        materialnumber      TYPE string,
        storagelocation     TYPE string,
        batch               TYPE string,
        sfitemidref         TYPE string,
      END OF ty_mandatory_field.

    DATA:
      ls_mandatory_field TYPE ty_mandatory_field,
      lt_missing_field   TYPE string_table,
      lt_order_response  TYPE tt_order_response,
      lt_message         TYPE zcl_zsde002_so_create=>tt_message.

    DATA(lo_struct) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( ls_mandatory_field ) ).

    LOOP AT is_request-order ASSIGNING FIELD-SYMBOL(<lfs_order>).

      CLEAR: lt_message[],
             lt_missing_field[].

      APPEND INITIAL LINE TO lt_order_response ASSIGNING FIELD-SYMBOL(<lfs_order_response>).
      IF <lfs_order_response> IS ASSIGNED.

        <lfs_order_response>-salesordernumber  = ''.
        <lfs_order_response>-documenttype      = <lfs_order>-salesordertype.
        <lfs_order_response>-customerreference = <lfs_order>-customerreference.
        <lfs_order_response>-sfheaderidref     = <lfs_order>-sfheaderidref.
        <lfs_order_response>-processingdate    = get_current_date( ).
        <lfs_order_response>-processingtime    = get_current_time( ).

        " Validate Mandatory Fields
        CLEAR lt_missing_field[].
        LOOP AT lo_struct->components ASSIGNING FIELD-SYMBOL(<lfs_components>).
          ASSIGN COMPONENT <lfs_components>-name OF STRUCTURE <lfs_order> TO FIELD-SYMBOL(<lv_value>).
          IF sy-subrc = 0 AND <lv_value> IS INITIAL.
            IF <lfs_components>-name = 'STOCKVAN'.
              IF <lfs_order>-processtype IN lr_processtype_stockvan.
                APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
              ENDIF.

            ELSEIF <lfs_components>-name = 'PAYMENTTRANSACTIONREFERENCE'.
              IF <lfs_order>-processtype IN lr_processtype_zt01.
                APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
              ENDIF.

            ELSEIF <lfs_components>-name = 'TAXDOCUMENTNO'.
              IF <lfs_order>-processtype IN lr_processtype_zt02.
                APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
              ENDIF.

            ELSEIF <lfs_components>-name = 'ORDERREASON'.
              IF <lfs_order>-trantype IN lr_trantype_reason.
                APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
              ENDIF.

            ELSEIF <lfs_components>-name = 'ORDERREASONTEXT'.
              IF <lfs_order>-orderreason IN lr_order_reason.
                APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
              ENDIF.

            ELSE.
              APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
            ENDIF.
          ENDIF.
        ENDLOOP.

        LOOP AT <lfs_order>-item ASSIGNING FIELD-SYMBOL(<lfs_item>).
          LOOP AT lo_struct->components ASSIGNING <lfs_components>.
            ASSIGN COMPONENT <lfs_components>-name OF STRUCTURE <lfs_item> TO <lv_value>.
            IF sy-subrc = 0 AND <lv_value> IS INITIAL.
              IF <lfs_components>-name = 'MATERIALNUMBER'.
                IF <lfs_item>-customermaterial IS INITIAL.
                  APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
                ENDIF.

              ELSEIF <lfs_components>-name = 'STORAGELOCATION'.
                IF <lfs_order>-processtype IN lr_processtype_sloc.
                  APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
                ENDIF.

              ELSEIF <lfs_components>-name = 'BATCH'.
                IF <lfs_order>-processtype IN lr_processtype_batch.
                  APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
                ENDIF.

              ELSEIF <lfs_components>-name = 'SFITEMIDREF'.
                IF <lfs_order>-processtype IN lr_processtype_sfid.
                  APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
                ENDIF.

              ELSE.
                APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
              ENDIF.
            ENDIF.
          ENDLOOP.
        ENDLOOP.

        LOOP AT lt_missing_field ASSIGNING FIELD-SYMBOL(<lfs_missing_field>).
          APPEND VALUE #( status  = 'E'
                          message = |Mandatory field { <lfs_missing_field> } is missing.|
                        ) TO lt_message.
        ENDLOOP.

        " Validate Process Type
        IF <lfs_order>-processtype NOT IN lr_processtype.
          APPEND VALUE #( status  = 'E'
                          message = |Invalid Process Type { <lfs_order>-processtype }.|
                        ) TO lt_message.
        ENDIF.

        " Validate Sales Area + Partner
        DATA ls_salesarea         TYPE I_SalesArea.
        DATA ls_customersalesarea TYPE I_CustomerSalesArea.
        DATA lr_customer          TYPE RANGE OF I_CustomerSalesArea-Customer.
        DATA lv_customer          TYPE I_CustomerSalesArea-Customer.

        ls_salesarea-SalesOrganization            = |{ <lfs_order>-salesorganization ALPHA = IN }|.
        ls_salesarea-DistributionChannel          = |{ <lfs_order>-distributionchannel ALPHA = IN }|.
        ls_salesarea-Division                     = |{ <lfs_order>-division ALPHA = IN }|.
        ls_customersalesarea-CustomerPaymentTerms = |{ <lfs_order>-paymentterm ALPHA = IN }|.

        APPEND VALUE #( sign   = 'I'
                        option = 'EQ'
                        low    = |{ <lfs_order>-soldtoparty ALPHA = IN }|
                      ) TO lr_customer.

        APPEND VALUE #( sign   = 'I'
                        option = 'EQ'
                        low    = |{ <lfs_order>-shiptoparty ALPHA = IN }|
                      ) TO lr_customer.

        APPEND VALUE #( sign   = 'I'
                        option = 'EQ'
                        low    = |{ <lfs_order>-billtoparty ALPHA = IN }|
                      ) TO lr_customer.

        APPEND VALUE #( sign   = 'I'
                        option = 'EQ'
                        low    = |{ <lfs_order>-payer ALPHA = IN }|
                      ) TO lr_customer.

        APPEND VALUE #( sign   = 'I'
                        option = 'EQ'
                        low    = |{ <lfs_order>-stockvan ALPHA = IN }|
                      ) TO lr_customer.

        SELECT FROM I_SalesArea AS sa
          INNER JOIN I_CustomerSalesArea AS csa
            ON  csa~SalesOrganization   = sa~SalesOrganization
            AND csa~DistributionChannel = sa~DistributionChannel
            AND csa~Division            = sa~Division
          FIELDS sa~SalesOrganization,
                 sa~DistributionChannel,
                 sa~Division,
                 csa~Customer,
                 csa~CustomerPaymentTerms,
                 csa~OrderIsBlockedForCustomer
          WHERE sa~SalesOrganization   = @ls_salesarea-SalesOrganization
            AND sa~DistributionChannel = @ls_salesarea-DistributionChannel
            AND sa~Division            = @ls_salesarea-Division
            AND csa~Customer           IN @lr_customer
          INTO TABLE @DATA(lt_CustomerSalesArea).

        " Validate Sales Area
        IF NOT LINE_EXISTS( lt_CustomerSalesArea[ SalesOrganization = ls_salesarea-SalesOrganization ] ).
          APPEND VALUE #( status  = 'E'
                          message = |Sales Organization { <lfs_order>-salesorganization } is not valid.|
                        ) TO lt_message.
        ENDIF.

        IF NOT LINE_EXISTS( lt_CustomerSalesArea[ DistributionChannel = ls_salesarea-DistributionChannel ] ).
          APPEND VALUE #( status  = 'E'
                          message = |Distribution Channel { <lfs_order>-distributionchannel } is not valid.|
                        ) TO lt_message.
        ENDIF.

        IF NOT LINE_EXISTS( lt_CustomerSalesArea[ Division = ls_salesarea-Division ] ).
          APPEND VALUE #( status  = 'E'
                          message = |Division { <lfs_order>-division } is not valid.|
                        ) TO lt_message.
        ENDIF.

        IF NOT LINE_EXISTS( lt_CustomerSalesArea[ SalesOrganization   = ls_salesarea-SalesOrganization
                                                  DistributionChannel = ls_salesarea-DistributionChannel
                                                  Division            = ls_salesarea-Division ] ).
          APPEND VALUE #( status  = 'E'
                          message = |Sales Area { <lfs_order>-salesorganization }/{ <lfs_order>-distributionchannel }/{ <lfs_order>-division } is not valid.|
                        ) TO lt_message.
        ENDIF.

        " Validate Sold-to Party
        CLEAR lv_customer.
        lv_customer = |{ <lfs_order>-soldtoparty ALPHA = IN }|.
        IF NOT LINE_EXISTS( lt_CustomerSalesArea[ SalesOrganization   = ls_salesarea-SalesOrganization
                                                  DistributionChannel = ls_salesarea-DistributionChannel
                                                  Division            = ls_salesarea-Division
                                                  Customer            = lv_customer ] ).
          APPEND VALUE #( status  = 'E'
                          message = |Sold-to Party { <lfs_order>-soldtoparty } does not exist or is not valid.|
                        ) TO lt_message.
        ENDIF.

        " Validate Ship-to Party
        CLEAR lv_customer.
        lv_customer = |{ <lfs_order>-shiptoparty ALPHA = IN }|.
        IF NOT LINE_EXISTS( lt_CustomerSalesArea[ SalesOrganization   = ls_salesarea-SalesOrganization
                                                  DistributionChannel = ls_salesarea-DistributionChannel
                                                  Division            = ls_salesarea-Division
                                                  Customer            = lv_customer ] ).
          APPEND VALUE #( status  = 'E'
                          message = |Ship-to Party { <lfs_order>-shiptoparty } does not exist or is not valid.|
                        ) TO lt_message.
        ENDIF.

        " Validate Bill-to Party
        CLEAR lv_customer.
        lv_customer = |{ <lfs_order>-billtoparty ALPHA = IN }|.
        IF NOT LINE_EXISTS( lt_CustomerSalesArea[ SalesOrganization   = ls_salesarea-SalesOrganization
                                                  DistributionChannel = ls_salesarea-DistributionChannel
                                                  Division            = ls_salesarea-Division
                                                  Customer            = lv_customer ] ).
          APPEND VALUE #( status  = 'E'
                          message = |Bill-to Party { <lfs_order>-billtoparty } does not exist or is not valid.|
                        ) TO lt_message.
        ENDIF.

        " Validate Payer
        CLEAR lv_customer.
        lv_customer = |{ <lfs_order>-payer ALPHA = IN }|.
        IF NOT LINE_EXISTS( lt_CustomerSalesArea[ SalesOrganization   = ls_salesarea-SalesOrganization
                                                  DistributionChannel = ls_salesarea-DistributionChannel
                                                  Division            = ls_salesarea-Division
                                                  Customer            = lv_customer ] ).
          APPEND VALUE #( status  = 'E'
                          message = |Payer Party { <lfs_order>-payer } does not exist or is not valid.|
                        ) TO lt_message.
        ENDIF.

        " Validate Stock Van
        CLEAR lv_customer.
        lv_customer = |{ <lfs_order>-stockvan ALPHA = IN }|.
        IF NOT LINE_EXISTS( lt_CustomerSalesArea[ SalesOrganization   = ls_salesarea-SalesOrganization
                                                  DistributionChannel = ls_salesarea-DistributionChannel
                                                  Division            = ls_salesarea-Division
                                                  Customer            = lv_customer ] ).
          APPEND VALUE #( status  = 'E'
                          message = |Stock Van { <lfs_order>-stockvan } does not exist or is not valid.|
                        ) TO lt_message.
        ENDIF.

        " Validate Sales Document Type
        SELECT SINGLE FROM I_SalesDocumentType
          FIELDS SalesDocumentType
          WHERE SalesDocumentType = @<lfs_order>-salesordertype
          INTO @DATA(lv_SalesDocumentType).

        IF sy-subrc <> 0.
          APPEND VALUE #( status  = 'E'
                          message = |Sales Document Type { <lfs_order>-salesordertype } is not valid.|
                        ) TO lt_message.
        ENDIF.

        " Validate Payment Term
        SELECT SINGLE FROM I_PaymentTerms
          FIELDS PaymentTerms
          WHERE PaymentTerms = @<lfs_order>-paymentterm
          INTO @DATA(lv_PaymentTerms).

        IF sy-subrc <> 0.
          APPEND VALUE #( status  = 'E'
                          message = |Payment Term { <lfs_order>-paymentterm } is not valid.|
                        ) TO lt_message.
        ENDIF.

        " Validate Item
        LOOP AT <lfs_order>-item ASSIGNING <lfs_item>.

          " Validate Material
          SELECT SINGLE FROM I_Product
            FIELDS Product
            WHERE Product = @<lfs_item>-customermaterial
            INTO @DATA(lv_Product).

          IF sy-subrc <> 0.
            APPEND VALUE #( status  = 'E'
                            message = |Material { <lfs_item>-customermaterial } does not exist or is not valid.|
                          ) TO lt_message.
          ENDIF.

          " Validate Plant
          SELECT SINGLE FROM I_Plant
            FIELDS Plant
            WHERE Plant = @<lfs_item>-plant
            INTO @DATA(lv_Plant).

          IF sy-subrc <> 0.
            APPEND VALUE #( status  = 'E'
                            message = |Plant { <lfs_item>-plant } is not valid.|
                          ) TO lt_message.
          ENDIF.

          " Validate Storage Location
          SELECT SINGLE FROM I_StorageLocation
            FIELDS StorageLocation
            WHERE StorageLocation = @<lfs_item>-storagelocation
            INTO @DATA(lv_StorageLocation).

          IF sy-subrc <> 0.
            APPEND VALUE #( status  = 'E'
                            message = |Storage Location { <lfs_item>-storagelocation } is not valid.|
                          ) TO lt_message.
          ENDIF.

          " Validate Quantity
          IF <lfs_item>-requestedquantity IS INITIAL OR <lfs_item>-requestedquantity <= 0.
            APPEND VALUE #( status  = 'E'
                            message = |Invalid quantity { <lfs_item>-requestedquantity } or sales unit { <lfs_item>-salesunit }.|
                          ) TO lt_message.
          ENDIF.

          " Validate Sales Unit
          SELECT SINGLE FROM I_ProductUnitsOfMeasure
            FIELDS BaseUnit
            WHERE Product  = @<lfs_item>-customermaterial
              AND BaseUnit = @<lfs_item>-salesunit
            INTO @DATA(lv_BaseUnit).

          IF sy-subrc <> 0.
            APPEND VALUE #( status  = 'E'
                            message = |Sales Unit { <lfs_item>-salesunit } is not valid.|
                          ) TO lt_message.
          ENDIF.

          " Validate Item Pricing Element
          LOOP AT <lfs_item>-pricing ASSIGNING FIELD-SYMBOL(<lfs_pricing>).

            " Validate Condition Type
            SELECT SINGLE FROM I_ConditionType
              FIELDS ConditionType
              WHERE ConditionType = @<lfs_pricing>-conditiontype
              INTO @DATA(lv_ConditionType).

            IF sy-subrc <> 0.
              APPEND VALUE #( status  = 'E'
                              message = |Condition Type { <lfs_pricing>-conditiontype } is not valid.|
                            ) TO lt_message.
            ENDIF.

            " Validate Pricing Currency
            SELECT SINGLE FROM I_Currency
              FIELDS Currency
              WHERE Currency = @<lfs_pricing>-conditioncurrency
              INTO @DATA(lv_Currency).

            IF sy-subrc <> 0.
              APPEND VALUE #( status  = 'E'
                              message = |Pricing Currency { <lfs_pricing>-conditioncurrency } is not valid.|
                            ) TO lt_message.
            ENDIF.

          ENDLOOP.

        ENDLOOP.

        <lfs_order_response>-message = lt_message.
        UNASSIGN <lfs_order_response>.
      ENDIF.

    ENDLOOP.

    IF LINE_EXISTS( lt_message[ status = 'E' ] ).
      es_response-requeststatus  = 'E'.
      es_response-requestmessage = 'Data validation failed'.
      es_response-order          = lt_order_response.
    ENDIF.

  ENDMETHOD.

  METHOD create_sales_order.

    DATA:
      lt_order_response TYPE tt_order_response,
      ls_order_response TYPE ty_order_response,
      lt_message        TYPE zcl_zsde002_so_create=>tt_message.

    LOOP AT is_request-order ASSIGNING FIELD-SYMBOL(<lfs_order>).

      " Generate group index
*      DATA(lv_idx) = sy-tabix.
*      IF <lfs_order>-requestid IS INITIAL.
*        <lfs_order>-requestid = |{ ls_request-requestid }-{ lv_idx }|.
*      ENDIF.

      " Create Sales Order
      DATA(ls_result) = zcl_zsde002_so_create=>create( EXPORTING is_request = <lfs_order>
                                                                 io_param   = lo_param ).
      MOVE-CORRESPONDING ls_result TO ls_order_response.

      IF ls_order_response-salesordernumber IS NOT INITIAL.
        ev_total_success = ev_total_success + 1.
      ELSE.
        ev_total_error = ev_total_error + 1.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD to_json_format.
    rv_json = /ui2/cl_json=>serialize( data        = is_data
                                       pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
  ENDMETHOD.

  METHOD handle_get.

    DATA:
      lt_order         TYPE tt_order,
      lt_item          TYPE tt_item,
      lt_order_pricing TYPE tt_pricing,
      lt_item_pricing  TYPE tt_pricing,
      ls_response      TYPE ty_metadata.

    APPEND VALUE #( conditiontype          = 'OrderConditionType1'
                    conditionamount        = ''
                    conditioncurrency      = ''
                    conditionpricingunit   = ''
                    conditionunitofmeasure = ''
                  ) TO lt_order_pricing.

    APPEND VALUE #( conditiontype          = 'OrderConditionType2'
                    conditionamount        = ''
                    conditioncurrency      = ''
                    conditionpricingunit   = ''
                    conditionunitofmeasure = ''
                  ) TO lt_order_pricing.

    APPEND VALUE #( conditiontype          = 'ItemConditionType1'
                    conditionamount        = ''
                    conditioncurrency      = ''
                    conditionpricingunit   = ''
                    conditionunitofmeasure = ''
                  ) TO lt_item_pricing.

    APPEND VALUE #( conditiontype          = 'ItemConditionType2'
                    conditionamount        = ''
                    conditioncurrency      = ''
                    conditionpricingunit   = ''
                    conditionunitofmeasure = ''
                  ) TO lt_item_pricing.

    APPEND VALUE #( item              = 'SalesOrderItem1'
                    materialnumber    = ''
                    customermaterial  = ''
                    itemcategory      = ''
                    requestedquantity = ''
                    salesunit         = ''
                    plant             = ''
                    storagelocation   = ''
                    mattaxclass       = ''
                    salestext         = ''
                    unittext          = ''
                    promotionidtext   = ''
                    batch             = ''
                    route             = ''
                    sfitemidref       = ''
                    pricing           = lt_item_pricing
                  ) TO lt_item.

    APPEND VALUE #( item              = 'SalesOrderItem2'
                    materialnumber    = ''
                    customermaterial  = ''
                    itemcategory      = ''
                    requestedquantity = ''
                    salesunit         = ''
                    plant             = ''
                    storagelocation   = ''
                    mattaxclass       = ''
                    salestext         = ''
                    unittext          = ''
                    promotionidtext   = ''
                    batch             = ''
                    route             = ''
                    sfitemidref       = ''
                    pricing           = lt_item_pricing
                  ) TO lt_item.

    APPEND VALUE #(
      sfheaderidref               = ''
      salesordertempid            = ''
      processtype                 = ''
      trantype                    = ''
      salesordertype              = ''
      salesorganization           = ''
      distributionchannel         = ''
      division                    = ''
      soldtoparty                 = ''
      customerbranch              = ''
      shiptoparty                 = ''
      billtoparty                 = ''
      payer                       = ''
      stockvan                    = ''
      customerreference           = ''
      customerreferencedate       = ''
      documentdate                = ''
      reqdeliverydate             = ''
      shippingconditions          = ''
      paymenttransactionreference = ''
      taxdocumentno               = ''
      relateddocumentreference    = ''
      currency                    = ''
      paymentterm                 = ''
      originalsalesdocument       = ''
      orderreason                 = ''
      orderreasontext             = ''
      customerpo                  = ''
      pricing                     = lt_order_pricing
      item                        = lt_item
    ) TO lt_order.

    ls_response-requestid = 'YYYYMMDD_hhmmss'.
    ls_response-order     = lt_order.

    " Response
    co_http_response->set_text( to_json_format( ls_response ) ).

  ENDMETHOD.

  METHOD handle_post.

    DATA:
      ls_request        TYPE ty_deep_request,
      ls_response       TYPE ty_deep_response,
      lv_total_success  TYPE i,
      lv_total_error    TYPE i,
      ls_result         TYPE zcl_zsde002_so_create=>ty_result,
      ls_system_message TYPE zcl_zsde002_so_create=>ty_sys_message.

    " Get payload
    DATA(lv_body) = io_http_request->get_text( ).

    " Set output data as JSON format
    co_http_response->set_header_field( i_name = 'content-type' i_value = 'application/json' ).

    " Send output no payload or wrong format
    IF lv_body IS INITIAL OR lv_body(1) <> '{'.
      co_http_response->set_status( i_code = 400 i_reason = 'Bad Request' ).
      co_http_response->set_text( to_json_format( VALUE ty_http_error( status  = 'E'
                                                                       message = 'Request body is not valid JSON format' ) ) ).
      RETURN.
    ENDIF.

    " Convert JSON to ABAP structure
    TRY.
        xco_cp_json=>data->from_string( lv_body )->write_to( REF #( ls_request ) ).
      CATCH cx_root.
        co_http_response->set_status( i_code = 400 i_reason = 'Bad Request' ).
        co_http_response->set_text( to_json_format( VALUE ty_http_error( status  = 'E'
                                                                         message = 'Request body is not valid JSON format' ) ) ).
        RETURN.
    ENDTRY.

    " Force Response with mock-up body for Postman Testing and skip all process below
    force_response( CHANGING cs_response      = ls_response
                             co_http_response = co_http_response ).
    RETURN.

    " Send payload but no detail for POST
    IF ls_request-order IS INITIAL.
      co_http_response->set_status( i_code = 400 i_reason = 'Bad Request' ).
      co_http_response->set_text( to_json_format( VALUE ty_http_error( status  = 'E'
                                                                       message = 'Request body contain no order' ) ) ).
      RETURN.
    ENDIF.

    " Get Constant Parameters
    get_constant_param( CHANGING cs_response = ls_response ).

    IF lo_param->gt_param IS INITIAL.
      ls_response-requeststatus  = 'E'.
      ls_response-requestmessage = |No constant parameter found.|.
      co_http_response->set_status( i_code = 200 i_reason = 'OK' ).
      RETURN.
    ENDIF.

    " Validate Data
    validate_data( EXPORTING is_request  = ls_request
                   IMPORTING es_response = ls_response ).

    IF ls_response-requeststatus  = 'E'.
      co_http_response->set_status( i_code = 200 i_reason = 'OK' ).
      RETURN.
    ENDIF.

    " Create Sales Order
    create_sales_order( EXPORTING is_request       = ls_request
                        IMPORTING es_response      = ls_response
                                  ev_total_success = lv_total_success
                                  ev_total_error   = lv_total_error ).

    " Create response message
    IF lv_total_error = 0.
      ls_response-requeststatus  = 'S'.
      ls_response-requestmessage = |{ lv_total_success } order(s) created|.
      co_http_response->set_status( i_code = 201 i_reason = 'Created' ).
    ELSEIF lv_total_success = 0.
      ls_response-requeststatus  = 'E'.
      ls_response-requestmessage = |{ lv_total_error } order(s) failed|.
      co_http_response->set_status( i_code = 200 i_reason = 'OK' ).
    ELSE.
      ls_response-requeststatus  = 'W'.
      ls_response-requestmessage = |{ lv_total_success } created, { lv_total_error } failed|.
      co_http_response->set_status( i_code = 200 i_reason = 'OK' ).
    ENDIF.

    " Response
    co_http_response->set_text( to_json_format( ls_response ) ).

  ENDMETHOD.

  METHOD get_current_date.

    TRY.
        DATA(lv_tzone) = cl_abap_context_info=>get_user_time_zone( ).
      CATCH cx_abap_context_info_error.
        "handle exception
    ENDTRY.

    DATA(lv_tstmp) = utclong_current( ).

    CONVERT UTCLONG lv_tstmp
            INTO DATE DATA(lv_loc_date)
                 TIME DATA(lv_loc_time)
            TIME ZONE lv_tzone.

    rv_date = |{ lv_loc_date+6(2) }-{ lv_loc_date+4(2) }-{ lv_loc_date(4) }|.

  ENDMETHOD.

  METHOD get_current_time.

    TRY.
        DATA(lv_tzone) = cl_abap_context_info=>get_user_time_zone( ).
      CATCH cx_abap_context_info_error.
        "handle exception
    ENDTRY.

    DATA(lv_tstmp) = utclong_current( ).

    CONVERT UTCLONG lv_tstmp
            INTO DATE DATA(lv_loc_date)
                 TIME DATA(lv_loc_time)
            TIME ZONE lv_tzone.

    rv_time = |{ lv_loc_time+4(2) }:{ lv_loc_time+2(2) }:{ lv_loc_time(2) }|.

  ENDMETHOD.

  METHOD force_response.

    DATA: lt_order_response  TYPE tt_order_response,
          lt_message         TYPE zcl_zsde002_so_create=>tt_message.

    APPEND VALUE #( status  = 'Status'
                    message = 'Message 1'
                  ) TO lt_message.

    APPEND VALUE #( status  = 'Status'
                    message = 'Message 2'
                  ) TO lt_message.

    APPEND VALUE #( salesordernumber  = 'SalesOrderNumber 1'
                    documenttype      = 'DocumentType'
                    customerreference = 'CustomerReference'
                    sfheaderidref     = 'SFHeaderIdRef'
                    processingdate    = get_current_date( )
                    processingtime    = get_current_time( )
                    message           = lt_message
                  ) TO lt_order_response.

    APPEND VALUE #( salesordernumber  = 'SalesOrderNumber 2'
                    documenttype      = 'DocumentType'
                    customerreference = 'CustomerReference'
                    sfheaderidref     = 'SFHeaderIdRef'
                    processingdate    = get_current_date( )
                    processingtime    = get_current_time( )
                    message           = lt_message
                  ) TO lt_order_response.

    cs_response-requeststatus  = 'S'.
    cs_response-requestmessage = |Test connection success|.
    cs_response-order          = lt_order_response.

    co_http_response->set_status( i_code = 200 i_reason = 'OK' ).
    co_http_response->set_text( to_json_format( cs_response ) ).

  ENDMETHOD.

ENDCLASS.
