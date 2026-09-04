CLASS zcl_zsde002_http DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .

    " Request Type -----------------------------------------------------
    TYPES:
      BEGIN OF ty_pricing,
        condition_type            TYPE string,
        condition_amount          TYPE string,
        condition_currency        TYPE string,
        condition_pricing_unit    TYPE string,
        condition_unit_of_measure TYPE string,
      END OF ty_pricing,
      tt_pricing TYPE STANDARD TABLE OF ty_pricing WITH EMPTY KEY,

      BEGIN OF ty_item,
        " Item Data
        item               TYPE string,
        material_number    TYPE string,
        customer_material  TYPE string,
        item_category      TYPE string,
        requested_quantity TYPE string,
        sales_unit         TYPE string,
        plant              TYPE string,
        storage_location   TYPE string,
        mat_tax_class      TYPE string,
        sales_text         TYPE string,
        unit_text          TYPE string,
        promotion_id_text  TYPE string,
        batch              TYPE string,
        route              TYPE string,
        sf_item_id_ref     TYPE string,
        " Item Pricing Data
        pricings           TYPE tt_pricing,
      END OF ty_item,
      tt_item TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY,

      BEGIN OF ty_order_in,
        " Header Data
        sf_header_id_ref              TYPE string,
        sales_order_temp_id           TYPE string,
        process_type                  TYPE string,
        tran_type                     TYPE string,
        sales_order_type              TYPE string,
        sales_organization            TYPE string,
        distribution_channel          TYPE string,
        division                      TYPE string,
        sold_to_party                 TYPE string,
        customer_branch               TYPE string,
        ship_to_party                 TYPE string,
        bill_to_party                 TYPE string,
        payer                         TYPE string,
        stock_van                     TYPE string,
        customer_reference            TYPE string,
        customer_reference_date       TYPE string,
        document_date                 TYPE string,
        req_delivery_date             TYPE string,
        shipping_conditions           TYPE string,
        payment_transaction_reference TYPE string,
        tax_document_no               TYPE string,
        related_document_reference    TYPE string,
        currency                      TYPE string,
        payment_term                  TYPE string,
        original_sales_document       TYPE string,
        order_reason                  TYPE string,
        order_reason_text             TYPE string,
        customer_po                   TYPE string,
        " Header Pricing Data
        pricings                      TYPE tt_pricing,
        " Item Data
        items                         TYPE tt_item,
           END OF ty_order_in,
      tt_order_in TYPE STANDARD TABLE OF ty_order_in WITH EMPTY KEY,

      BEGIN OF ty_request,
        request_id TYPE string,
        orders     TYPE tt_order_in,
      END OF ty_request.

    " Response Type ----------------------------------------------------
    TYPES:
      "! 1 แถว = 1 message — order ที่สำเร็จได้ 1 แถว, order ที่พังได้ 1 แถวต่อ 1 error
      BEGIN OF ty_order_out,
        status             TYPE string,
        code               TYPE string,
        message            TYPE string,
        sales_order_number TYPE string,
        document_type      TYPE string,
        customer_reference TYPE string,
        sf_header_id_ref   TYPE string,
        sf_item_id_ref     TYPE string,
        processing_date    TYPE string,
        processing_time    TYPE string,
        field              TYPE string,
      END OF ty_order_out,
      tt_order_out TYPE STANDARD TABLE OF ty_order_out WITH EMPTY KEY,

      BEGIN OF ty_response,
        request_id TYPE string,
        status     TYPE string,
        " เปิดใช้เมื่อ SBPA ต้องการตัวนับ — processor คำนวณไว้ให้อยู่แล้ว
*        passed     TYPE i,
*        failed     TYPE i,
        orders     TYPE tt_order_out,
      END OF ty_response.

  PROTECTED SECTION.
  PRIVATE SECTION.

    " Handle Methods ---------------------------------------------------
    METHODS handle_get
      CHANGING co_http_response TYPE REF TO if_web_http_response.

    METHODS handle_post
      IMPORTING io_http_request  TYPE REF TO if_web_http_request
      CHANGING  co_http_response TYPE REF TO if_web_http_response.

    METHODS set_sample_request_body
      RETURNING VALUE(rs_request) TYPE ty_request.

    METHODS set_sample_response_body
      RETURNING VALUE(rs_response) TYPE ty_response.

ENDCLASS.



CLASS zcl_zsde002_http IMPLEMENTATION.

  METHOD if_http_service_extension~handle_request.

    CASE request->get_method( ).
      WHEN 'GET'.
        handle_get( CHANGING co_http_response = response ).

      WHEN 'POST'.
        handle_post( EXPORTING io_http_request  = request
                     CHANGING  co_http_response = response ).

      WHEN OTHERS.
        response->set_status( i_code   = 405
                              i_reason = 'Method Not Allowed' ).
        RETURN.

    ENDCASE.

  ENDMETHOD.


  METHOD handle_get.

    co_http_response->set_header_field( i_name  = 'Content-Type'
                                        i_value = 'application/json' ).

    co_http_response->set_status( i_code   = 200
                                  i_reason = 'OK' ).

    co_http_response->set_text( xco_cp_json=>data->from_abap( set_sample_request_body(  )
                                )->apply( VALUE #( ( xco_cp_json=>transformation->underscore_to_pascal_case ) )
                                )->to_string( ) ).

  ENDMETHOD.


  METHOD handle_post.

    DATA(ls_result) = NEW zcl_zsde002_processor( )->process( io_http_request->get_text( ) ).

    DATA(ls_response) = VALUE ty_response(
      request_id = |{ ls_result-request_id }|
      status     = |{ ls_result-status }|
*      passed     = ls_result-passed
*      failed     = ls_result-failed
      orders     = VALUE #( FOR <lfs_order> IN ls_result-orders
                          ( status             = |{ <lfs_order>-status }|
                            code               = |ZSDE002/{ <lfs_order>-code }|
                            message            = <lfs_order>-message
                            sales_order_number = |{ <lfs_order>-sales_order_number }|
                            document_type      = |{ <lfs_order>-document_type }|
                            customer_reference = |{ <lfs_order>-customer_reference }|
                            sf_header_id_ref   = |{ <lfs_order>-sf_header_id_ref }|
                            sf_item_id_ref     = |{ <lfs_order>-sf_item_id_ref }|
                            processing_date    = <lfs_order>-processing_date
                            processing_time    = <lfs_order>-processing_time
                            field              = <lfs_order>-field ) ) ).

    co_http_response->set_header_field( i_name  = 'Content-Type'
                                        i_value = 'application/json' ).

    co_http_response->set_status( i_code   = COND #( WHEN ls_response-status = `E` THEN 400 ELSE 200 )
                                  i_reason = COND #( WHEN ls_response-status = `E` THEN 'Bad Request' ELSE 'OK' ) ).

    co_http_response->set_text( xco_cp_json=>data->from_abap( ls_response
                                )->apply( VALUE #( ( xco_cp_json=>transformation->underscore_to_pascal_case ) )
                                )->to_string( ) ).

  ENDMETHOD.


  METHOD set_sample_request_body.

    rs_request-request_id = 'YYYYMMDD_hhmmss'.

    DO 2 TIMES.
      APPEND INITIAL LINE TO rs_request-orders ASSIGNING FIELD-SYMBOL(<lfs_order>).
      <lfs_order>-sf_header_id_ref = |SfHeaderIdRef-{ sy-index }|.

      DO 2 TIMES.
        APPEND INITIAL LINE TO <lfs_order>-pricings ASSIGNING FIELD-SYMBOL(<lfs_order_pricing>).
        <lfs_order_pricing>-condition_type = |ConditionType-{ sy-index }|.
      ENDDO.

      DO 2 TIMES.
        APPEND INITIAL LINE TO <lfs_order>-items ASSIGNING FIELD-SYMBOL(<lfs_item>).
        <lfs_item>-sf_item_id_ref = |SfItemIdRef-{ sy-index }|.

        DO 2 TIMES.
          APPEND INITIAL LINE TO <lfs_item>-pricings ASSIGNING FIELD-SYMBOL(<lfs_item_pricing>).
          <lfs_item_pricing>-condition_type = |ConditionType-{ sy-index }|.
        ENDDO.
      ENDDO.
    ENDDO.

  ENDMETHOD.


  METHOD set_sample_response_body.

    rs_response-request_id = '99991231_235959'.
    rs_response-status     = 'W'.

    DO 3 TIMES.
      APPEND VALUE #( status             = 'S'
                      code               = 'ZSDE002/500'
                      message            = |Sales order 900000000{ sy-index } created|
                      sales_order_number = |900000000{ sy-index }|
                      document_type      = 'ZOR'
                      customer_reference = |CustomerReference-{ sy-index }|
                      sf_header_id_ref   = |SfHeaderIdRef-{ sy-index }|
                      processing_date    = '31-12-9999'
                      processing_time    = '23:59:59'
                    ) TO rs_response-orders.
    ENDDO.

    DO 2 TIMES.
      DATA(lv_index) = sy-index + 3.

      APPEND VALUE #( status             = 'E'
                      code               = 'ZSDE002/100'
                      message            = |Mandatory field SOLD_TO_PARTY is missing|
                      document_type      = 'ZOR'
                      customer_reference = |CustomerReference-{ lv_index }|
                      sf_header_id_ref   = |SfHeaderIdRef-{ lv_index }|
                      sf_item_id_ref     = |SfItemIdRef-{ lv_index }|
                      processing_date    = '31-12-9999'
                      processing_time    = '23:59:59'
                      field              = 'SoldToParty'
                    ) TO rs_response-orders.
    ENDDO.

  ENDMETHOD.

ENDCLASS.
