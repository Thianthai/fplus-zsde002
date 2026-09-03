CLASS zcl_zsde002_json DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      ty_request TYPE zcl_zsde002_http=>ty_request,
      ty_order   TYPE zcl_zsde002_http=>ty_order_in,
      ty_item    TYPE zcl_zsde002_http=>ty_item,
      tt_item    TYPE zcl_zsde002_http=>tt_item.

    "! แปลง JSON payload เป็น structure ของ table
    "! ชื่อ field แปลงอัตโนมัติจาก PascalCase เป็น snake_case ด้วย pascal_case_to_underscore
    CLASS-METHODS parse_json_request
      IMPORTING iv_body    TYPE string
      EXPORTING es_request TYPE ty_request
      RAISING   zcx_zsde002_error.

    "! แปลงชื่อ field snake_case ของ table เป็นชื่อ JSON PascalCase
    CLASS-METHODS to_json_name
      IMPORTING iv_field         TYPE string
      RETURNING VALUE(rv_result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-METHODS to_internal_date
      IMPORTING iv_value         TYPE string
      RETURNING VALUE(rv_result) TYPE string.

ENDCLASS.



CLASS zcl_zsde002_json IMPLEMENTATION.

  METHOD parse_json_request.

    CLEAR es_request.

    TRY.
        xco_cp_json=>data->from_string( iv_body
          )->apply( VALUE #( ( xco_cp_json=>transformation->pascal_case_to_underscore ) )
          )->write_to( REF #( es_request ) ).

      CATCH cx_root INTO DATA(lo_error).
        RAISE EXCEPTION TYPE zcx_zsde002_error
          EXPORTING iv_msgv1 = |JSON parse failed: { lo_error->get_text( ) }|.
    ENDTRY.

  ENDMETHOD.


  METHOD to_internal_date.

    IF iv_value IS INITIAL.
      RETURN.
    ENDIF.

    rv_result = iv_value.
    rv_result = replace( val = rv_result sub = `-` with = `` occ = 0 ).
    rv_result = replace( val = rv_result sub = `/` with = `` occ = 0 ).
    rv_result = replace( val = rv_result sub = `.` with = `` occ = 0 ).

  ENDMETHOD.


  METHOD to_json_name.

    CHECK iv_field IS NOT INITIAL.

    SPLIT to_lower( iv_field ) AT `_` INTO TABLE DATA(lt_part).

    LOOP AT lt_part ASSIGNING FIELD-SYMBOL(<lfs_part>).
      IF <lfs_part> IS INITIAL.
        CONTINUE.
      ENDIF.
      rv_result = |{ rv_result }| &&
                  |{ to_upper( substring( val = <lfs_part> len = 1 ) ) }| &&
                  |{ substring( val = <lfs_part> off = 1 ) }|.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
