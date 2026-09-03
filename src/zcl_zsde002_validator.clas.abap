CLASS zcl_zsde002_validator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      ty_order TYPE ztsd_e002_order,
      ty_item  TYPE ztsd_e002_item,
      tt_item  TYPE STANDARD TABLE OF ztsd_e002_item WITH EMPTY KEY,
      ty_param TYPE zcl_zsde002_processor=>ty_param.

    " ผลการตรวจ 1 ข้อ — ผู้เรียกแปลงเป็น message ต่อ
    TYPES:
      BEGIN OF ty_finding,
        msgno TYPE symsgno,
        msgty TYPE symsgty,
        msgv1 TYPE string,
        msgv2 TYPE string,
        msgv3 TYPE string,
        msgv4 TYPE string,
        field TYPE string,
      END OF ty_finding,
      tt_finding TYPE STANDARD TABLE OF ty_finding WITH EMPTY KEY.

    CLASS-METHODS to_internal_customer
      IMPORTING iv_value         TYPE clike
      RETURNING VALUE(rv_result) TYPE I_CustomerSalesArea-Customer.

    CLASS-METHODS to_internal_material
      IMPORTING iv_value         TYPE clike
      RETURNING VALUE(rv_result) TYPE I_Product-Product.

    CLASS-METHODS is_valid_date
      IMPORTING iv_value         TYPE clike
      RETURNING VALUE(rv_result) TYPE abap_bool.

    CLASS-METHODS is_valid_number
      IMPORTING iv_value         TYPE clike
      RETURNING VALUE(rv_result) TYPE abap_bool.

    CLASS-METHODS check_order_mandatory
      IMPORTING is_order          TYPE ty_order
                is_param          TYPE ty_param
      RETURNING VALUE(rt_finding) TYPE tt_finding.

    CLASS-METHODS check_item_mandatory
      IMPORTING is_order          TYPE ty_order
                is_item           TYPE ty_item
                is_param          TYPE ty_param
      RETURNING VALUE(rt_finding) TYPE tt_finding.

    CLASS-METHODS check_order_format
      IMPORTING is_order          TYPE ty_order
                it_pricing        TYPE zcl_zsde002_processor=>tt_order_pricing
      RETURNING VALUE(rt_finding) TYPE tt_finding.

    CLASS-METHODS check_item_format
      IMPORTING is_item           TYPE ty_item
                it_pricing        TYPE zcl_zsde002_processor=>tt_item_pricing
      RETURNING VALUE(rt_finding) TYPE tt_finding.

  PRIVATE SECTION.

    " ชื่อ component = ชื่อ column ใน table = ชื่อที่ส่งกลับใน error.field
    TYPES:
      BEGIN OF ty_mandatory_header,
        " บังคับเสมอ
        sales_order_temp_id           TYPE string,
        process_type                  TYPE string,
        tran_type                     TYPE string,
        sales_order_type              TYPE string,
        sales_organization            TYPE string,
        distribution_channel          TYPE string,
        division                      TYPE string,
        sold_to_party                 TYPE string,
        ship_to_party                 TYPE string,
        bill_to_party                 TYPE string,
        payer                         TYPE string,
        customer_reference            TYPE string,
        document_date                 TYPE string,
        shipping_conditions           TYPE string,
        sf_header_id_ref              TYPE string,
        " บังคับตามเงื่อนไข
        stock_van                     TYPE string,
        payment_transaction_reference TYPE string,
        tax_document_no               TYPE string,
        order_reason                  TYPE string,
        order_reason_text             TYPE string,
      END OF ty_mandatory_header,

      BEGIN OF ty_mandatory_item,
        material_number  TYPE string,
        storage_location TYPE string,
        batch            TYPE string,
        sf_item_id_ref   TYPE string,
      END OF ty_mandatory_item.

ENDCLASS.



CLASS zcl_zsde002_validator IMPLEMENTATION.

  METHOD to_internal_customer.

    DATA lv_customer TYPE I_CustomerSalesArea-Customer.

    lv_customer = iv_value.
    rv_result   = |{ lv_customer ALPHA = IN }|.

  ENDMETHOD.


  METHOD to_internal_material.

    " conversion exit ALPHA ของ MATNR เติมศูนย์ถึง 18 ตัว ไม่ใช่ความยาวของ field (40)
    " ถ้าประกาศตัวแปรเป็น I_Product-Product แล้ว ALPHA จะเติมศูนย์ยาว 40 ซึ่งผิด
    DATA lv_material TYPE c LENGTH 18.

    IF strlen( iv_value ) > 18.
      rv_result = iv_value.
      RETURN.
    ENDIF.

    lv_material = iv_value.
    rv_result   = |{ lv_material ALPHA = IN }|.

  ENDMETHOD.


  METHOD is_valid_date.

    " ตรวจหลังผ่าน to_internal_date จะได้ validate ค่าที่จะถูกส่งเข้า SAP จริงๆ
    " รับได้ทั้ง 2026-08-30 / 2026/08/30 / 2026.08.30 / 20260830
    DATA(lv_internal) = zcl_zsde002_json=>to_internal_date( CONV #( iv_value ) ).

    rv_result = xsdbool( matches( val  = lv_internal
                                  pcre = '^\d{4}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])$' ) ).

  ENDMETHOD.


  METHOD is_valid_number.

    DATA(lv_value) = condense( CONV string( iv_value ) ).

    rv_result = xsdbool( matches( val  = lv_value
                                  pcre = '^[+-]?\d+(\.\d+)?$' ) ).

  ENDMETHOD.


  METHOD check_order_mandatory.

    DATA ls_mandatory TYPE ty_mandatory_header.

    DATA(lo_struct) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( ls_mandatory ) ).

    LOOP AT lo_struct->components ASSIGNING FIELD-SYMBOL(<lfs_component>).

      ASSIGN COMPONENT <lfs_component>-name OF STRUCTURE is_order TO FIELD-SYMBOL(<lv_value>).
      IF sy-subrc <> 0 OR <lv_value> IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      DATA(lv_field) = CONV string( <lfs_component>-name ).

      CASE lv_field.

        WHEN 'STOCK_VAN'.
          IF is_order-process_type IN is_param-lr_processtype_stockvan.
            APPEND VALUE #( msgno = '101'
                            msgty = 'E'
                            msgv1 = lv_field
                            msgv2 = |{ is_order-process_type }|
                            field = lv_field ) TO rt_finding.
          ENDIF.

        WHEN 'PAYMENT_TRANSACTION_REFERENCE'.
          IF is_order-process_type IN is_param-lr_processtype_zt01.
            APPEND VALUE #( msgno = '101'
                            msgty = 'E'
                            msgv1 = lv_field
                            msgv2 = |{ is_order-process_type }|
                            field = lv_field ) TO rt_finding.
          ENDIF.

        WHEN 'TAX_DOCUMENT_NO'.
          IF is_order-process_type IN is_param-lr_processtype_zt02.
            APPEND VALUE #( msgno = '101'
                            msgty = 'E'
                            msgv1 = lv_field
                            msgv2 = |{ is_order-process_type }|
                            field = lv_field ) TO rt_finding.
          ENDIF.

        WHEN 'ORDER_REASON'.
          IF is_order-tran_type IN is_param-lr_trantype_reason.
            APPEND VALUE #( msgno = '102'
                            msgty = 'E'
                            msgv1 = lv_field
                            msgv2 = |{ is_order-tran_type }|
                            field = lv_field ) TO rt_finding.
          ENDIF.

        WHEN 'ORDER_REASON_TEXT'.
          IF is_order-order_reason IN is_param-lr_order_reason.
            APPEND VALUE #( msgno = '103'
                            msgty = 'E'
                            msgv1 = lv_field
                            msgv2 = |{ is_order-order_reason }|
                            field = lv_field ) TO rt_finding.
          ENDIF.

        WHEN OTHERS.
          APPEND VALUE #( msgno = '100'
                          msgty = 'E'
                          msgv1 = lv_field
                          field = lv_field ) TO rt_finding.

      ENDCASE.

    ENDLOOP.

  ENDMETHOD.


  METHOD check_item_mandatory.

    DATA ls_mandatory TYPE ty_mandatory_item.

    DATA(lo_struct) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( ls_mandatory ) ).

    DATA(lv_item) = |{ is_item-item }|.

    LOOP AT lo_struct->components ASSIGNING FIELD-SYMBOL(<lfs_component>).

      ASSIGN COMPONENT <lfs_component>-name OF STRUCTURE is_item TO FIELD-SYMBOL(<lv_value>).
      IF sy-subrc <> 0 OR <lv_value> IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      DATA(lv_field) = CONV string( <lfs_component>-name ).

      CASE lv_field.

        WHEN 'MATERIAL_NUMBER'.
          IF is_item-customer_material IS INITIAL.
            APPEND VALUE #( msgno = '151'
                            msgty = 'E'
                            msgv1 = lv_item
                            field = lv_field ) TO rt_finding.
          ENDIF.

        WHEN 'STORAGE_LOCATION'.
          IF is_order-process_type IN is_param-lr_processtype_sloc.
            APPEND VALUE #( msgno = '150'
                            msgty = 'E'
                            msgv1 = lv_item
                            msgv2 = lv_field
                            field = lv_field ) TO rt_finding.
          ENDIF.

        WHEN 'BATCH'.
          IF is_order-process_type IN is_param-lr_processtype_batch.
            APPEND VALUE #( msgno = '150'
                            msgty = 'E'
                            msgv1 = lv_item
                            msgv2 = lv_field
                            field = lv_field ) TO rt_finding.
          ENDIF.

        WHEN 'SF_ITEM_ID_REF'.
          IF is_order-process_type IN is_param-lr_processtype_sfid.
            APPEND VALUE #( msgno = '150'
                            msgty = 'E'
                            msgv1 = lv_item
                            msgv2 = lv_field
                            field = lv_field ) TO rt_finding.
          ENDIF.

        WHEN OTHERS.
          APPEND VALUE #( msgno = '150'
                          msgty = 'E'
                          msgv1 = lv_item
                          msgv2 = lv_field
                          field = lv_field ) TO rt_finding.

      ENDCASE.

    ENDLOOP.

  ENDMETHOD.


  METHOD check_order_format.

    IF  is_order-customer_reference_date IS NOT INITIAL
    AND is_valid_date( is_order-customer_reference_date ) = abap_false.
      APPEND VALUE #( msgno = '300'
                      msgty = 'E'
                      msgv1 = `customer_reference_date`
                      msgv2 = |{ is_order-customer_reference_date }|
                      field = `customer_reference_date` ) TO rt_finding.
    ENDIF.

    IF  is_order-document_date IS NOT INITIAL
    AND is_valid_date( is_order-document_date ) = abap_false.
      APPEND VALUE #( msgno = '300'
                      msgty = 'E'
                      msgv1 = `document_date`
                      msgv2 = |{ is_order-document_date }|
                      field = `document_date` ) TO rt_finding.
    ENDIF.

    IF  is_order-req_delivery_date IS NOT INITIAL
    AND is_valid_date( is_order-req_delivery_date ) = abap_false.
      APPEND VALUE #( msgno = '300'
                      msgty = 'E'
                      msgv1 = `req_delivery_date`
                      msgv2 = |{ is_order-req_delivery_date }|
                      field = `req_delivery_date` ) TO rt_finding.
    ENDIF.

    LOOP AT it_pricing ASSIGNING FIELD-SYMBOL(<lfs_pricing>).
      IF  <lfs_pricing>-condition_amount IS NOT INITIAL
      AND is_valid_number( <lfs_pricing>-condition_amount ) = abap_false.
        APPEND VALUE #( msgno = '302'
                        msgty = 'E'
                        msgv1 = |{ <lfs_pricing>-condition_type }|
                        msgv2 = |{ <lfs_pricing>-condition_amount }|
                        field = `condition_amount` ) TO rt_finding.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD check_item_format.

    DATA(lv_item) = |{ is_item-item }|.

    IF  is_item-requested_quantity IS NOT INITIAL
    AND is_valid_number( is_item-requested_quantity ) = abap_false.
      APPEND VALUE #( msgno = '301'
                      msgty = 'E'
                      msgv1 = lv_item
                      msgv2 = |{ is_item-requested_quantity }|
                      field = `requested_quantity` ) TO rt_finding.
    ENDIF.

    LOOP AT it_pricing ASSIGNING FIELD-SYMBOL(<lfs_pricing>).
      IF  <lfs_pricing>-condition_amount IS NOT INITIAL
      AND is_valid_number( <lfs_pricing>-condition_amount ) = abap_false.
        APPEND VALUE #( msgno = '302'
                        msgty = 'E'
                        msgv1 = |{ <lfs_pricing>-condition_type }|
                        msgv2 = |{ <lfs_pricing>-condition_amount }|
                        field = `condition_amount` ) TO rt_finding.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
