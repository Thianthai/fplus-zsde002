*"* use this source file for your ABAP unit test classes
CLASS ltcl_material DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS numeric_pads_to_18          FOR TESTING.
    METHODS longer_than_18_passes_thru  FOR TESTING.
    METHODS alphanumeric_is_not_padded  FOR TESTING.
    METHODS blank_stays_blank           FOR TESTING.
    METHODS spaces_are_condensed_first  FOR TESTING.

    METHODS convert
      IMPORTING iv_value         TYPE string
      RETURNING VALUE(rv_result) TYPE string.

ENDCLASS.


CLASS ltcl_material IMPLEMENTATION.

  METHOD convert.
    " แปลงเป็น string เพื่อตัด trailing blank ของ CHAR(40) ออกก่อนเทียบ
    rv_result = CONV string( zcl_zsde002_validator=>to_internal_material( iv_value ) ).
  ENDMETHOD.

  METHOD numeric_pads_to_18.
    " เคยพลาดมาแล้ว: ALPHA = IN เติมเป็น 40 หลักแทนที่จะเป็น 18 ทำให้หา I_Product ไม่เจอ
    cl_abap_unit_assert=>assert_equals( act = convert( `100000374` )
                                        exp = `000000000100000374`
                                        msg = `material ตัวเลขล้วนต้องชิดขวาเติมศูนย์ครบ 18 หลัก` ).
  ENDMETHOD.

  METHOD longer_than_18_passes_thru.
    cl_abap_unit_assert=>assert_equals( act = convert( `1234567890123456789` )
                                        exp = `1234567890123456789`
                                        msg = `extended material number ต้องส่งผ่านตามเดิม` ).
  ENDMETHOD.

  METHOD alphanumeric_is_not_padded.
    cl_abap_unit_assert=>assert_equals( act = convert( `ABC123` )
                                        exp = `ABC123`
                                        msg = `MATNR แบบ alphanumeric ห้ามเติมศูนย์` ).
  ENDMETHOD.

  METHOD blank_stays_blank.
    cl_abap_unit_assert=>assert_initial( act = convert( `` )
                                         msg = `ค่าว่างต้องคืนค่าว่าง ไม่ใช่ศูนย์ 18 ตัว` ).
  ENDMETHOD.

  METHOD spaces_are_condensed_first.
    cl_abap_unit_assert=>assert_equals( act = convert( `  100000374  ` )
                                        exp = `000000000100000374`
                                        msg = `ช่องว่างหัวท้ายต้องถูกตัดก่อนเติมศูนย์` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_date_number DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS dash_format_is_valid        FOR TESTING.
    METHODS slash_format_is_valid       FOR TESTING.
    METHODS dot_format_is_valid         FOR TESTING.
    METHODS compact_format_is_valid     FOR TESTING.
    METHODS month_13_is_rejected        FOR TESTING.
    METHODS day_32_is_rejected          FOR TESTING.
    METHODS day_first_order_is_rejected FOR TESTING.
    METHODS blank_date_is_rejected      FOR TESTING.

    METHODS decimal_is_valid_number     FOR TESTING.
    METHODS signed_is_valid_number      FOR TESTING.
    METHODS thousand_separator_rejected FOR TESTING.
    METHODS letters_are_rejected        FOR TESTING.
    METHODS trailing_dot_is_rejected    FOR TESTING.

ENDCLASS.


CLASS ltcl_date_number IMPLEMENTATION.

  METHOD dash_format_is_valid.
    cl_abap_unit_assert=>assert_true( zcl_zsde002_validator=>is_valid_date( `2026-09-01` ) ).
  ENDMETHOD.

  METHOD slash_format_is_valid.
    cl_abap_unit_assert=>assert_true( zcl_zsde002_validator=>is_valid_date( `2026/09/01` ) ).
  ENDMETHOD.

  METHOD dot_format_is_valid.
    cl_abap_unit_assert=>assert_true( zcl_zsde002_validator=>is_valid_date( `2026.09.01` ) ).
  ENDMETHOD.

  METHOD compact_format_is_valid.
    cl_abap_unit_assert=>assert_true( zcl_zsde002_validator=>is_valid_date( `20260901` ) ).
  ENDMETHOD.

  METHOD month_13_is_rejected.
    cl_abap_unit_assert=>assert_false( zcl_zsde002_validator=>is_valid_date( `2026-13-01` ) ).
  ENDMETHOD.

  METHOD day_32_is_rejected.
    cl_abap_unit_assert=>assert_false( zcl_zsde002_validator=>is_valid_date( `2026-09-32` ) ).
  ENDMETHOD.

  METHOD day_first_order_is_rejected.
    " 01-09-2026 กลายเป็น 01092026 → ปี 0109 เดือน 20 ซึ่งเป็นไปไม่ได้
    cl_abap_unit_assert=>assert_false( zcl_zsde002_validator=>is_valid_date( `01-09-2026` ) ).
  ENDMETHOD.

  METHOD blank_date_is_rejected.
    cl_abap_unit_assert=>assert_false( zcl_zsde002_validator=>is_valid_date( `` ) ).
  ENDMETHOD.

  METHOD decimal_is_valid_number.
    cl_abap_unit_assert=>assert_true( zcl_zsde002_validator=>is_valid_number( `10.000` ) ).
  ENDMETHOD.

  METHOD signed_is_valid_number.
    cl_abap_unit_assert=>assert_true( zcl_zsde002_validator=>is_valid_number( `-1070.5` ) ).
  ENDMETHOD.

  METHOD thousand_separator_rejected.
    cl_abap_unit_assert=>assert_false( zcl_zsde002_validator=>is_valid_number( `1,070.00` ) ).
  ENDMETHOD.

  METHOD letters_are_rejected.
    cl_abap_unit_assert=>assert_false( zcl_zsde002_validator=>is_valid_number( `ten` ) ).
  ENDMETHOD.

  METHOD trailing_dot_is_rejected.
    cl_abap_unit_assert=>assert_false( zcl_zsde002_validator=>is_valid_number( `10.` ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_order_format DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS clean_order_has_no_finding  FOR TESTING.
    METHODS bad_date_reports_field_name FOR TESTING.
    METHODS bad_amount_reports_cond_typ FOR TESTING.
    METHODS blank_date_is_not_checked   FOR TESTING.

ENDCLASS.


CLASS ltcl_order_format IMPLEMENTATION.

  METHOD clean_order_has_no_finding.

    DATA(ls_order) = VALUE zcl_zsde002_validator=>ty_order(
                             customer_reference_date = '2026-09-01'
                             document_date           = '2026-09-01'
                             req_delivery_date       = '2026-09-01' ).

    cl_abap_unit_assert=>assert_initial(
      act = zcl_zsde002_validator=>check_order_format( is_order   = ls_order
                                                       it_pricing = VALUE #( ) )
      msg = `order ที่วันที่ถูกต้องทั้งหมดต้องไม่มี finding` ).

  ENDMETHOD.

  METHOD bad_date_reports_field_name.

    DATA(ls_order) = VALUE zcl_zsde002_validator=>ty_order( document_date = '2026-99-01' ).

    DATA(lt_finding) = zcl_zsde002_validator=>check_order_format( is_order   = ls_order
                                                                  it_pricing = VALUE #( ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_finding ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_finding[ 1 ]-msgno exp = '300' ).
    cl_abap_unit_assert=>assert_equals( act = lt_finding[ 1 ]-field
                                        exp = `document_date`
                                        msg = `field ต้องชี้ไปที่ column ที่ผิด ไม่ใช่ field อื่น` ).

  ENDMETHOD.

  METHOD bad_amount_reports_cond_typ.

    DATA(lt_pricing) = VALUE zcl_zsde002_processor=>tt_order_pricing(
                               ( condition_type = 'ZPI1' condition_amount = '1,070.00' ) ).

    DATA(lt_finding) = zcl_zsde002_validator=>check_order_format(
                         is_order   = VALUE #( )
                         it_pricing = lt_pricing ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_finding ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_finding[ 1 ]-msgno exp = '302' ).
    cl_abap_unit_assert=>assert_equals( act = lt_finding[ 1 ]-msgv1
                                        exp = `ZPI1`
                                        msg = `message ต้องบอกว่า condition type ไหนที่ผิด` ).

  ENDMETHOD.

  METHOD blank_date_is_not_checked.

    cl_abap_unit_assert=>assert_initial(
      act = zcl_zsde002_validator=>check_order_format( is_order   = VALUE #( )
                                                       it_pricing = VALUE #( ) )
      msg = `field ที่ว่างไม่ใช่ปัญหาของ format check — mandatory check เป็นคนดู` ).

  ENDMETHOD.

ENDCLASS.
