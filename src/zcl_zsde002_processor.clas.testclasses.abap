CLASS ltcl_duplicate   DEFINITION DEFERRED.
CLASS ltcl_pretty_json DEFINITION DEFERRED.
CLASS ltcl_order_out   DEFINITION DEFERRED.

CLASS zcl_zsde002_processor DEFINITION LOCAL FRIENDS ltcl_duplicate
                                                     ltcl_pretty_json
                                                     ltcl_order_out.


"! test double — ทุก method คืนค่าว่าง แปลว่า master data ครบและยังไม่มี reference ไหนถูกใช้
CLASS ltd_master_data DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_zsde002_master_data.
ENDCLASS.

CLASS ltd_master_data IMPLEMENTATION.
  METHOD zif_zsde002_master_data~read_process_type.           ENDMETHOD.
  METHOD zif_zsde002_master_data~read_used_customer_ref.      ENDMETHOD.
  METHOD zif_zsde002_master_data~find_unknown_sales_area.     ENDMETHOD.
  METHOD zif_zsde002_master_data~find_unknown_cust_sales_area. ENDMETHOD.
  METHOD zif_zsde002_master_data~find_unknown_sales_doc_type. ENDMETHOD.
  METHOD zif_zsde002_master_data~find_unknown_payment_terms.  ENDMETHOD.
  METHOD zif_zsde002_master_data~find_unknown_product.        ENDMETHOD.
  METHOD zif_zsde002_master_data~find_unknown_plant.          ENDMETHOD.
  METHOD zif_zsde002_master_data~find_unknown_storage_location. ENDMETHOD.
  METHOD zif_zsde002_master_data~find_unknown_product_unit.   ENDMETHOD.
  METHOD zif_zsde002_master_data~find_unknown_condition_type. ENDMETHOD.
  METHOD zif_zsde002_master_data~find_unknown_currency.       ENDMETHOD.
ENDCLASS.


CLASS ltcl_duplicate DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA go_cut TYPE REF TO zcl_zsde002_processor.

    METHODS setup.

    METHODS all_unique_returns_nothing FOR TESTING.
    METHODS one_pair_is_reported_once  FOR TESTING.
    METHODS three_times_is_still_once  FOR TESTING.
    METHODS blanks_are_not_duplicates  FOR TESTING.
    METHODS case_matters               FOR TESTING.

ENDCLASS.


CLASS ltcl_duplicate IMPLEMENTATION.

  METHOD setup.
    go_cut = NEW zcl_zsde002_processor( io_master_data = NEW ltd_master_data( ) ).
  ENDMETHOD.

  METHOD all_unique_returns_nothing.
    cl_abap_unit_assert=>assert_initial(
      go_cut->find_duplicate_value( VALUE #( ( `SF-1` ) ( `SF-2` ) ( `SF-3` ) ) ) ).
  ENDMETHOD.

  METHOD one_pair_is_reported_once.

    DATA(lt_result) = go_cut->find_duplicate_value( VALUE #( ( `SF-1` ) ( `SF-2` ) ( `SF-1` ) ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_result ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_result[ 1 ] exp = `SF-1` ).

  ENDMETHOD.

  METHOD three_times_is_still_once.

    " ทุกใบที่ถือค่าซ้ำจะตกหมด แต่ค่าที่ซ้ำต้องรายงานครั้งเดียว
    " ไม่งั้น line_exists ฝั่งผู้เรียกจะทำงานเหมือนเดิมแต่ตารางบวมโดยเปล่าประโยชน์
    cl_abap_unit_assert=>assert_equals(
      act = lines( go_cut->find_duplicate_value( VALUE #( ( `X` ) ( `X` ) ( `X` ) ) ) )
      exp = 1 ).

  ENDMETHOD.

  METHOD blanks_are_not_duplicates.

    " order ที่ไม่ส่ง SfHeaderIdRef มาหลายใบ ไม่ใช่ความผิดของกฎ duplicate
    " mandatory check เป็นคนรายงาน ไม่ใช่ message 015
    cl_abap_unit_assert=>assert_initial(
      go_cut->find_duplicate_value( VALUE #( ( `` ) ( `` ) ( `SF-1` ) ) ) ).

  ENDMETHOD.

  METHOD case_matters.
    cl_abap_unit_assert=>assert_initial(
      act = go_cut->find_duplicate_value( VALUE #( ( `SF-1` ) ( `sf-1` ) ) )
      msg = `ตัวพิมพ์ต่างกันคือคนละค่า — SAP เก็บตามที่ส่งมา` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_pretty_json DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA go_cut TYPE REF TO zcl_zsde002_processor.

    METHODS setup.

    METHODS nested_object_splits_lines  FOR TESTING.
    METHODS indent_uses_nbsp            FOR TESTING.
    METHODS empty_object_stays_inline   FOR TESTING.
    METHODS empty_array_stays_inline    FOR TESTING.
    METHODS braces_in_text_are_literal  FOR TESTING.
    METHODS escaped_quote_is_literal    FOR TESTING.
    METHODS colon_gets_one_space        FOR TESTING.

    METHODS nbsp
      RETURNING VALUE(rv_result) TYPE string.

ENDCLASS.


CLASS ltcl_pretty_json IMPLEMENTATION.

  METHOD setup.
    go_cut = NEW zcl_zsde002_processor( io_master_data = NEW ltd_master_data( ) ).
  ENDMETHOD.

  METHOD nbsp.
    rv_result = cl_abap_conv_codepage=>create_in( )->convert( CONV xstring( 'C2A0' ) ).
  ENDMETHOD.

  METHOD nested_object_splits_lines.

    DATA(lv_out) = go_cut->to_pretty_json( `{"A":"1","B":{"C":"2"}}` ).

    SPLIT lv_out AT |\n| INTO TABLE DATA(lt_line).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_line ) exp = 6
                                        msg = |ควรได้ 6 บรรทัด แต่ได้: { lv_out }| ).

  ENDMETHOD.

  METHOD indent_uses_nbsp.

    " space ธรรมดาถูกยุบทิ้งตอน render ในหน้า monitor — indent จึงต้องเป็น NBSP
    DATA(lv_out) = go_cut->to_pretty_json( `{"A":"1"}` ).

    SPLIT lv_out AT |\n| INTO TABLE DATA(lt_line).

    cl_abap_unit_assert=>assert_equals( act = substring( val = lt_line[ 2 ] len = 2 )
                                        exp = nbsp( ) && nbsp( )
                                        msg = `บรรทัดที่ 2 ต้องขึ้นต้นด้วย NBSP สองตัว ไม่ใช่ space` ).

  ENDMETHOD.

  METHOD empty_object_stays_inline.
    cl_abap_unit_assert=>assert_equals( act = go_cut->to_pretty_json( `{}` )
                                        exp = `{}` ).
  ENDMETHOD.

  METHOD empty_array_stays_inline.

    DATA(lv_out) = go_cut->to_pretty_json( `{"Items":[]}` ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( contains( val = lv_out sub = `[]` ) )
                                      msg = `array ว่างไม่ควรกินสองบรรทัด` ).

  ENDMETHOD.

  METHOD braces_in_text_are_literal.

    " field ข้อความอาจมีปีกกาหรือ comma อยู่ข้างใน ต้องไม่ถูกนับเป็นโครงสร้าง
    DATA(lv_out) = go_cut->to_pretty_json( `{"Text":"a{b,c}d"}` ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( contains( val = lv_out sub = `"a{b,c}d"` ) )
                                      msg = |ข้อความถูกหั่น: { lv_out }| ).

  ENDMETHOD.

  METHOD escaped_quote_is_literal.

    " \" ข้างใน string ไม่ได้ปิด string — ถ้าอ่านผิดจะหลุดออกมาแล้วจัดรูปแบบพัง
    DATA(lv_json) = `{"Text":"say \"hi\"","B":"2"}`.

    DATA(lv_out) = go_cut->to_pretty_json( lv_json ).

    SPLIT lv_out AT |\n| INTO TABLE DATA(lt_line).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_line ) exp = 4
                                        msg = |escape ถูกอ่านผิด: { lv_out }| ).

  ENDMETHOD.

  METHOD colon_gets_one_space.
    cl_abap_unit_assert=>assert_true(
      xsdbool( contains( val = go_cut->to_pretty_json( `{"A":"1"}` ) sub = `"A": "1"` ) ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_order_out DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA go_cut TYPE REF TO zcl_zsde002_processor.

    METHODS setup.

    METHODS success_is_one_row          FOR TESTING.
    METHODS each_error_gets_a_row       FOR TESTING.
    METHODS warning_does_not_make_a_row FOR TESTING.
    METHODS failure_without_error_is_501 FOR TESTING.
    METHODS time_is_bangkok_not_utc     FOR TESTING.

    METHODS order
      RETURNING VALUE(rs_result) TYPE zcl_zsde002_processor=>ty_order.

ENDCLASS.


CLASS ltcl_order_out IMPLEMENTATION.

  METHOD setup.
    go_cut = NEW zcl_zsde002_processor( io_master_data = NEW ltd_master_data( ) ).
  ENDMETHOD.

  METHOD order.

    " 2026-09-06 07:22:57 UTC = 14:22:57 ตามเวลาไทย
    " สร้างด้วย CONVERT แทนการ assign literal เพราะ created_at เป็น packed ที่มีทศนิยม
    " การเขียนเลขลงไปตรงๆ ไม่รับประกันว่าจะได้ค่าที่ CONVERT TIME STAMP อ่านออก
    CONVERT DATE '20260906' TIME '072257'
            INTO TIME STAMP rs_result-created_at TIME ZONE 'UTC'.

    rs_result-sf_header_id_ref   = 'SF-001'.
    rs_result-customer_reference = 'PO-001'.
    rs_result-sales_order_type   = 'Z201'.

  ENDMETHOD.

  METHOD success_is_one_row.

    DATA(ls_order) = order( ).
    ls_order-sales_order_number = 'O210000007'.
    ls_order-order_status       = 'S'.

    DATA(lt_out) = go_cut->to_order_out( is_order = ls_order
                                         it_error = VALUE #( ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_out ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_out[ 1 ]-status exp = 'S' ).
    cl_abap_unit_assert=>assert_equals( act = lt_out[ 1 ]-code   exp = `500` ).
    cl_abap_unit_assert=>assert_equals( act = lt_out[ 1 ]-sales_order_number exp = 'O210000007' ).
    cl_abap_unit_assert=>assert_initial( act = lt_out[ 1 ]-field
                                         msg = `แถวที่สำเร็จต้องไม่มี field ชี้ไปที่ไหน` ).

  ENDMETHOD.

  METHOD each_error_gets_a_row.

    DATA(ls_order) = order( ).
    ls_order-order_status = 'E'.

    DATA(lt_error) = VALUE zcl_zsde002_processor=>tt_error(
      ( msgno = '100' msgty = 'E' msgtx = `Mandatory field X is missing` field = `Payer` )
      ( msgno = '207' msgty = 'E' msgtx = `Ship-to Party is not valid`   field = `ShipToParty` ) ).

    DATA(lt_out) = go_cut->to_order_out( is_order = ls_order
                                         it_error = lt_error ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_out ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_out[ 1 ]-code  exp = `100` ).
    cl_abap_unit_assert=>assert_equals( act = lt_out[ 2 ]-code  exp = `207` ).
    cl_abap_unit_assert=>assert_equals( act = lt_out[ 2 ]-field exp = `ShipToParty` ).

  ENDMETHOD.

  METHOD warning_does_not_make_a_row.

    " SO สร้างสำเร็จแต่มี warning ติดมา ยังนับเป็นสำเร็จ ไม่แตกเป็นแถว error
    DATA(ls_order) = order( ).
    ls_order-sales_order_number = 'O210000007'.
    ls_order-order_status       = 'W'.

    DATA(lt_out) = go_cut->to_order_out(
                     is_order = ls_order
                     it_error = VALUE #( ( msgno = '014' msgty = 'W' msgtx = `Request ID too long` ) ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_out ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_out[ 1 ]-code exp = `500` ).

  ENDMETHOD.

  METHOD failure_without_error_is_501.

    " ไม่ควรเกิด แต่ถ้าเกิด order ต้องไม่หายไปจาก response เฉยๆ
    DATA(ls_order) = order( ).
    ls_order-order_status = 'E'.

    DATA(lt_out) = go_cut->to_order_out( is_order = ls_order
                                         it_error = VALUE #( ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_out ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_out[ 1 ]-code exp = `501` ).

  ENDMETHOD.

  METHOD time_is_bangkok_not_utc.

    " created_at 07:22:57 UTC → 14:22:57 ตามเวลาไทย
    " เทสตัวนี้สร้าง order เองแทนที่จะใช้ helper เพราะสิ่งที่ตรวจคือตัว timestamp
    " ค่า input จึงควรอยู่ในสายตาบรรทัดเดียวกับค่าที่คาดหวัง
    DATA ls_order TYPE zcl_zsde002_processor=>ty_order.

    CONVERT DATE '20260906' TIME '072257'
            INTO TIME STAMP ls_order-created_at TIME ZONE 'UTC'.

    ls_order-sf_header_id_ref   = 'SF-001'.
    ls_order-sales_order_type   = 'Z201'.
    ls_order-sales_order_number = 'O210000007'.
    ls_order-order_status       = 'S'.

    DATA(lt_out) = go_cut->to_order_out( is_order = ls_order
                                         it_error = VALUE #( ) ).

    " 00:00:00 = gc_time_zone ไม่มีอยู่จริง CONVERT TIME STAMP ล้มเงียบด้วย sy-subrc 8
    " 07:22:57 = gc_time_zone กลับไปเป็น UTC หรือกลับไปอ่านจาก user context
    cl_abap_unit_assert=>assert_equals(
      act = lt_out[ 1 ]-processing_time
      exp = `14:22:57`
      msg = |ได้ "{ lt_out[ 1 ]-processing_time }" — ดู comment เหนือบรรทัดนี้| ).

    cl_abap_unit_assert=>assert_equals( act = lt_out[ 1 ]-processing_date
                                        exp = `06-09-2026` ).

  ENDMETHOD.

ENDCLASS.
