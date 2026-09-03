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

    CLASS-METHODS check_order_mandatory
      IMPORTING is_order          TYPE ty_order
                is_param          TYPE ty_param
      RETURNING VALUE(rt_finding) TYPE tt_finding.

    CLASS-METHODS check_item_mandatory
      IMPORTING is_order          TYPE ty_order
                is_item           TYPE ty_item
                is_param          TYPE ty_param
      RETURNING VALUE(rt_finding) TYPE tt_finding.

  PRIVATE SECTION.

    " ชื่อ component = ชื่อ column ใน table = ชื่อที่ส่งกลับใน error.field
    TYPES:
      BEGIN OF ty_mandatory_field,
        " Header
        sales_order_temp_id  TYPE string,
        process_type         TYPE string,
        tran_type            TYPE string,
        sales_order_type     TYPE string,
        sales_organization   TYPE string,
        distribution_channel TYPE string,
        division             TYPE string,
        sold_to_party        TYPE string,
        ship_to_party        TYPE string,
        bill_to_party        TYPE string,
        payer                TYPE string,
        customer_reference   TYPE string,
        document_date        TYPE string,
        shipping_conditions  TYPE string,
        sf_header_id_ref     TYPE string,
        " Item
        material_number      TYPE string,
        storage_location     TYPE string,
        batch                TYPE string,
        sf_item_id_ref       TYPE string,
      END OF ty_mandatory_field.

ENDCLASS.



CLASS zcl_zsde002_validator IMPLEMENTATION.

  METHOD to_internal_customer.

    DATA lv_customer TYPE I_CustomerSalesArea-Customer.

    lv_customer = iv_value.
    rv_result   = |{ lv_customer ALPHA = IN }|.

  ENDMETHOD.


  METHOD check_order_mandatory.

    DATA:
      ls_mandatory_field TYPE ty_mandatory_field,
      lt_missing_field   TYPE string_table.

    DATA(lo_struct) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( ls_mandatory_field ) ).

    LOOP AT lo_struct->components ASSIGNING FIELD-SYMBOL(<lfs_components>).

      ASSIGN COMPONENT <lfs_components>-name OF STRUCTURE is_order TO FIELD-SYMBOL(<lv_value>).
      IF sy-subrc = 0 AND <lv_value> IS INITIAL.

        " TODO 5 branch ข้างล่างยังเป็น dead code — component เหล่านี้ยังไม่มีใน
        "      ty_mandatory_field จึงไม่มีทางถูก LOOP ถึง (finding ข้อ 8)
        IF <lfs_components>-name = 'STOCK_VAN'.
          IF is_order-process_type IN is_param-lr_processtype_stockvan.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'PAYMENT_TRANSACTION_REFERENCE'.
          IF is_order-process_type IN is_param-lr_processtype_zt01.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'TAX_DOCUMENT_NO'.
          IF is_order-process_type IN is_param-lr_processtype_zt02.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'ORDER_REASON'.
          IF is_order-tran_type IN is_param-lr_trantype_reason.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'ORDER_REASON_TEXT'.
          IF is_order-order_reason IN is_param-lr_processtype_zt04.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSE.
          APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
        ENDIF.
      ENDIF.

    ENDLOOP.

    LOOP AT lt_missing_field ASSIGNING FIELD-SYMBOL(<lfs_missing_field>).
      APPEND VALUE #( msgno = '100'
                      msgty = 'E'
                      msgv1 = <lfs_missing_field>
                      field = <lfs_missing_field>
                    ) TO rt_finding.
    ENDLOOP.

  ENDMETHOD.


  METHOD check_item_mandatory.

    DATA:
      ls_mandatory_field TYPE ty_mandatory_field,
      lt_missing_field   TYPE string_table.

    DATA(lo_struct) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( ls_mandatory_field ) ).

    LOOP AT lo_struct->components ASSIGNING FIELD-SYMBOL(<lfs_components>).

      ASSIGN COMPONENT <lfs_components>-name OF STRUCTURE is_item TO FIELD-SYMBOL(<lv_value>).
      IF sy-subrc = 0 AND <lv_value> IS INITIAL.

        IF <lfs_components>-name = 'MATERIAL_NUMBER'.
          IF is_item-customer_material IS INITIAL.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'STORAGE_LOCATION'.
          IF is_order-process_type IN is_param-lr_processtype_sloc.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'BATCH'.
          IF is_order-process_type IN is_param-lr_processtype_batch.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'SF_ITEM_ID_REF'.
          IF is_order-process_type IN is_param-lr_processtype_sfid.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSE.
          APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.

        ENDIF.

      ENDIF.
    ENDLOOP.

    LOOP AT lt_missing_field ASSIGNING FIELD-SYMBOL(<lfs_missing_field>).
      APPEND VALUE #( msgno = '100'
                      msgty = 'E'
                      msgv1 = <lfs_missing_field>
                      field = <lfs_missing_field>
                    ) TO rt_finding.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
