CLASS zcl_zsde002_http DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .

    " Request Type -----------------------------------------------------
    TYPES:
      BEGIN OF ty_pricing,
        conditiontype          TYPE string,
        conditionamount        TYPE p LENGTH 11 DECIMALS 2,
        conditioncurrency      TYPE string,
        conditionpricingunit   TYPE p LENGTH 5 DECIMALS 0,
        conditionunitofmeasure TYPE string,
      END OF ty_pricing,
      tt_pricing TYPE STANDARD TABLE OF ty_pricing WITH EMPTY KEY,

      BEGIN OF ty_item,
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
        pricings          TYPE tt_pricing,
      END OF ty_item,
      tt_item TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY,

      BEGIN OF ty_order_in,
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
        pricings                    TYPE tt_pricing,
        " Item Data
        items                       TYPE tt_item,
           END OF ty_order_in,
      tt_order_in TYPE STANDARD TABLE OF ty_order_in WITH EMPTY KEY,

      BEGIN OF ty_request,
        request_id TYPE string,
        orders     TYPE tt_order_in,
      END OF ty_request.

    " Response Type ----------------------------------------------------
    TYPES:
      BEGIN OF ty_error,
        code          TYPE string,
        message       TYPE string,
        sfheaderidref TYPE string,
        sfitemidref   TYPE string,
        field         TYPE string,
      END OF ty_error,
      tt_error TYPE STANDARD TABLE OF ty_error WITH EMPTY KEY,

      BEGIN OF ty_order_out,
        salesordernumber  TYPE string,
        documenttype      TYPE string,
        customerreference TYPE string,
        sfheaderidref     TYPE string,
        processingdate    TYPE string,
        processingtime    TYPE string,
        errors            TYPE tt_error,
      END OF ty_order_out,
      tt_order_out TYPE STANDARD TABLE OF ty_order_out WITH EMPTY KEY,

      BEGIN OF ty_response,
        request_id TYPE string,
        passed     TYPE i,
        failed     TYPE i,
        errors     TYPE tt_error,
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

    METHODS set_request_body
      RETURNING VALUE(rs_request) TYPE ty_request.

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

    co_http_response->set_text( xco_cp_json=>data->from_abap( set_request_body(  )
                                )->apply( VALUE #( ( xco_cp_json=>transformation->underscore_to_pascal_case ) )
                                )->to_string( ) ).

  ENDMETHOD.


  METHOD handle_post.

    DATA(ls_result) = NEW zcl_zsde002_processor( )->process( io_http_request->get_text( ) ).

    DATA(ls_response) = VALUE ty_response( request_id = |{ ls_result-request_id }|
                                           passed     = ls_result-passed
                                           failed     = ls_result-failed
                                           errors     = VALUE #( FOR <lfs_error> IN ls_result-errors
                                                               ( code          = |ZSDE002/{ <lfs_error>-msgno }|
                                                                 message       = <lfs_error>-msgtx
                                                                 sfheaderidref = <lfs_error>-sfheaderidref
                                                                 sfitemidref   = <lfs_error>-sfitemidref
                                                                 field         = <lfs_error>-field ) )
                                           orders     = ls_result-orders ).

    co_http_response->set_header_field( i_name  = 'Content-Type'
                                        i_value = 'application/json' ).

    co_http_response->set_status( i_code   = COND #( WHEN ls_response-errors[] IS INITIAL THEN 200 ELSE 400 )
                                  i_reason = COND #( WHEN ls_response-errors[] IS INITIAL THEN 'OK' ELSE 'Bad Request' ) ).

    co_http_response->set_text( xco_cp_json=>data->from_abap( ls_response
                                )->apply( VALUE #( ( xco_cp_json=>transformation->underscore_to_pascal_case ) )
                                )->to_string( ) ).

  ENDMETHOD.


  METHOD set_request_body.

    rs_request-request_id = 'YYYYMMDD_hhmmss'.

    DO 2 TIMES.
      APPEND INITIAL LINE TO rs_request-orders ASSIGNING FIELD-SYMBOL(<lfs_order>).
      <lfs_order>-sfheaderidref = |SfHeaderIdRef-{ sy-index }|.

      DO 2 TIMES.
        APPEND INITIAL LINE TO <lfs_order>-pricings ASSIGNING FIELD-SYMBOL(<lfs_order_pricing>).
        <lfs_order_pricing>-conditiontype = |ConditionType-{ sy-index }|.

        APPEND INITIAL LINE TO <lfs_order>-items ASSIGNING FIELD-SYMBOL(<lfs_item>).
        <lfs_item>-sfitemidref = |SfItemIdRef-{ sy-index }|.

        DO 2 TIMES.
          APPEND INITIAL LINE TO <lfs_item>-pricings ASSIGNING FIELD-SYMBOL(<lfs_item_pricing>).
          <lfs_item_pricing>-conditiontype = |ConditionType-{ sy-index }|.
        ENDDO.
      ENDDO.
    ENDDO.

  ENDMETHOD.

ENDCLASS.
