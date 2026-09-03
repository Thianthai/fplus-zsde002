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

        IF <lfs_components>-name = 'STOCKVAN'.
          IF is_order-processtype IN is_param-lr_processtype_stockvan.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'PAYMENTTRANSACTIONREFERENCE'.
          IF is_order-processtype IN is_param-lr_processtype_zt01.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'TAXDOCUMENTNO'.
          IF is_order-processtype IN is_param-lr_processtype_zt02.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'ORDERREASON'.
          IF is_order-trantype IN is_param-lr_trantype_reason.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'ORDERREASONTEXT'.
          IF is_order-orderreason IN is_param-lr_processtype_zt04.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSE.
          APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
        ENDIF.
      ENDIF.

    ENDLOOP.

    LOOP AT lt_missing_field ASSIGNING FIELD-SYMBOL(<lfs_missing_field>).
      APPEND VALUE #( msgno = '100'
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

        IF <lfs_components>-name = 'MATERIALNUMBER'.
          IF is_item-customermaterial IS INITIAL.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'STORAGELOCATION'.
          IF is_order-processtype IN is_param-lr_processtype_sloc.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'BATCH'.
          IF is_order-processtype IN is_param-lr_processtype_batch.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSEIF <lfs_components>-name = 'SFITEMIDREF'.
          IF is_order-processtype IN is_param-lr_processtype_sfid.
            APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.
          ENDIF.

        ELSE.
          APPEND CONV string( <lfs_components>-name ) TO lt_missing_field.

        ENDIF.

      ENDIF.
    ENDLOOP.

    LOOP AT lt_missing_field ASSIGNING FIELD-SYMBOL(<lfs_missing_field>).
      APPEND VALUE #( msgno = '100'
                      msgv1 = <lfs_missing_field>
                      field = <lfs_missing_field>
                   ) TO rt_finding.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
