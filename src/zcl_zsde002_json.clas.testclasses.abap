CLASS ltcl_json_name DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS four_parts_become_pascal   FOR TESTING.
    METHODS single_word_is_capitalised FOR TESTING.
    METHODS abbreviation_keeps_shape   FOR TESTING.
    METHODS upper_case_input_is_lowered FOR TESTING.
    METHODS empty_stays_empty          FOR TESTING.
    METHODS stray_underscores_ignored  FOR TESTING.
    METHODS round_trip_of_every_field  FOR TESTING.

ENDCLASS.


CLASS ltcl_json_name IMPLEMENTATION.

  METHOD four_parts_become_pascal.
    cl_abap_unit_assert=>assert_equals( act = zcl_zsde002_json=>to_json_name( `sf_header_id_ref` )
                                        exp = `SfHeaderIdRef` ).
  ENDMETHOD.

  METHOD single_word_is_capitalised.
    cl_abap_unit_assert=>assert_equals( act = zcl_zsde002_json=>to_json_name( `payer` )
                                        exp = `Payer` ).
  ENDMETHOD.

  METHOD abbreviation_keeps_shape.
    " req ไม่ได้ถูกขยายเป็น requested — ชื่อใน JSON ต้องตรงกับ column ตัวต่อตัว
    cl_abap_unit_assert=>assert_equals( act = zcl_zsde002_json=>to_json_name( `req_delivery_date` )
                                        exp = `ReqDeliveryDate` ).
  ENDMETHOD.

  METHOD upper_case_input_is_lowered.
    cl_abap_unit_assert=>assert_equals( act = zcl_zsde002_json=>to_json_name( `DOCUMENT_DATE` )
                                        exp = `DocumentDate`
                                        msg = `ชื่อ component ที่มาจาก RTTI เป็นตัวใหญ่ ต้องแปลงได้เหมือนกัน` ).
  ENDMETHOD.

  METHOD empty_stays_empty.
    cl_abap_unit_assert=>assert_initial( zcl_zsde002_json=>to_json_name( `` ) ).
  ENDMETHOD.

  METHOD stray_underscores_ignored.
    cl_abap_unit_assert=>assert_equals( act = zcl_zsde002_json=>to_json_name( `_order__reason_` )
                                        exp = `OrderReason` ).
  ENDMETHOD.

  METHOD round_trip_of_every_field.

    " ชื่อทุกตัวที่ส่งกลับไปใน error.field ต้องเป็นชื่อเดียวกับที่ SBPA ส่งมาใน payload
    " ถ้า to_json_name กับ pascal_case_to_underscore ของ XCO ไม่เป็น inverse กัน
    " error จะชี้ไปที่ field ที่ไม่มีอยู่ใน request
    DATA(lt_pair) = VALUE string_table(
      ( `sf_header_id_ref|SfHeaderIdRef` )
      ( `sales_order_temp_id|SalesOrderTempId` )
      ( `process_type|ProcessType` )
      ( `sold_to_party|SoldToParty` )
      ( `customer_reference_date|CustomerReferenceDate` )
      ( `payment_transaction_reference|PaymentTransactionReference` )
      ( `original_sales_document|OriginalSalesDocument` )
      ( `order_reason_text|OrderReasonText` )
      ( `condition_unit_of_measure|ConditionUnitOfMeasure` )
      ( `promotion_id_text|PromotionIdText` )
      ( `sf_item_id_ref|SfItemIdRef` ) ).

    LOOP AT lt_pair ASSIGNING FIELD-SYMBOL(<lfs_pair>).
      SPLIT <lfs_pair> AT `|` INTO DATA(lv_column) DATA(lv_json).
      cl_abap_unit_assert=>assert_equals( act = zcl_zsde002_json=>to_json_name( lv_column )
                                          exp = lv_json
                                          msg = |{ lv_column } ต้องกลายเป็น { lv_json }| ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.


CLASS ltcl_internal_date DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS dash_is_stripped    FOR TESTING.
    METHODS slash_is_stripped   FOR TESTING.
    METHODS dot_is_stripped     FOR TESTING.
    METHODS compact_is_untouched FOR TESTING.
    METHODS empty_stays_empty   FOR TESTING.

ENDCLASS.


CLASS ltcl_internal_date IMPLEMENTATION.

  METHOD dash_is_stripped.
    cl_abap_unit_assert=>assert_equals( act = zcl_zsde002_json=>to_internal_date( `2026-09-01` )
                                        exp = `20260901` ).
  ENDMETHOD.

  METHOD slash_is_stripped.
    cl_abap_unit_assert=>assert_equals( act = zcl_zsde002_json=>to_internal_date( `2026/09/01` )
                                        exp = `20260901` ).
  ENDMETHOD.

  METHOD dot_is_stripped.
    cl_abap_unit_assert=>assert_equals( act = zcl_zsde002_json=>to_internal_date( `2026.09.01` )
                                        exp = `20260901` ).
  ENDMETHOD.

  METHOD compact_is_untouched.
    cl_abap_unit_assert=>assert_equals( act = zcl_zsde002_json=>to_internal_date( `20260901` )
                                        exp = `20260901` ).
  ENDMETHOD.

  METHOD empty_stays_empty.
    cl_abap_unit_assert=>assert_initial( zcl_zsde002_json=>to_internal_date( `` ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_parse DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS request_id_is_read       FOR TESTING.
    METHODS two_orders_are_read      FOR TESTING.
    METHODS header_fields_are_mapped FOR TESTING.
    METHODS items_are_nested         FOR TESTING.
    METHODS item_pricing_is_nested   FOR TESTING.
    METHODS broken_json_raises       FOR TESTING.
    METHODS unknown_field_is_ignored FOR TESTING.
    METHODS lower_case_name_is_lost  FOR TESTING.

    METHODS parse
      IMPORTING iv_body          TYPE string
      RETURNING VALUE(rs_result) TYPE zcl_zsde002_json=>ty_request.

    METHODS full_body
      RETURNING VALUE(rv_result) TYPE string.

ENDCLASS.


CLASS ltcl_parse IMPLEMENTATION.

  METHOD parse.

    TRY.
        zcl_zsde002_json=>parse_json_request( EXPORTING iv_body    = iv_body
                                              IMPORTING es_request = rs_result ).
      CATCH zcx_zsde002_error INTO DATA(lo_error).
        cl_abap_unit_assert=>fail( msg = |parse ล้มโดยไม่ควรล้ม: { lo_error->get_text( ) }| ).
    ENDTRY.

  ENDMETHOD.

  METHOD full_body.

    rv_result = concat_lines_of( table = VALUE string_table(
      ( `{` )
      ( `  "RequestId": "TEST-001",` )
      ( `  "Orders": [` )
      ( `    {` )
      ( `      "SfHeaderIdRef": "SF-001",` )
      ( `      "ProcessType": "310",` )
      ( `      "CustomerReference": "PO-001",` )
      ( `      "SoldToParty": "1000000006",` )
      ( `      "Pricings": [ { "ConditionType": "ZPI1", "ConditionAmount": "1070" } ],` )
      ( `      "Items": [` )
      ( `        { "Item": "10",` )
      ( `          "MaterialNumber": "100000374",` )
      ( `          "SalesUnit": "KAR",` )
      ( `          "Pricings": [ { "ConditionType": "ZPI1", "ConditionAmount": "1070" } ] },` )
      ( `        { "Item": "20",` )
      ( `          "MaterialNumber": "100000178",` )
      ( `          "SalesUnit": "KAR" }` )
      ( `      ]` )
      ( `    }` )
      ( `  ]` )
      ( `}` ) ) ).

  ENDMETHOD.

  METHOD request_id_is_read.
    cl_abap_unit_assert=>assert_equals( act = parse( full_body( ) )-request_id
                                        exp = `TEST-001` ).
  ENDMETHOD.

  METHOD two_orders_are_read.

    DATA(lv_body) = concat_lines_of( table = VALUE string_table(
      ( `{ "RequestId": "R1", "Orders": [` )
      ( `  { "SfHeaderIdRef": "SF-001" },` )
      ( `  { "SfHeaderIdRef": "SF-002" } ] }` ) ) ).

    DATA(ls_request) = parse( lv_body ).

    cl_abap_unit_assert=>assert_equals( act = lines( ls_request-orders ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = ls_request-orders[ 2 ]-sf_header_id_ref
                                        exp = `SF-002` ).

  ENDMETHOD.

  METHOD header_fields_are_mapped.

    DATA(ls_request) = parse( full_body( ) ).
    DATA(ls_order)   = ls_request-orders[ 1 ].

    cl_abap_unit_assert=>assert_equals( act = ls_order-sf_header_id_ref exp = `SF-001` ).
    cl_abap_unit_assert=>assert_equals( act = ls_order-process_type     exp = `310` ).
    cl_abap_unit_assert=>assert_equals( act = ls_order-sold_to_party    exp = `1000000006` ).
    cl_abap_unit_assert=>assert_equals( act = ls_order-pricings[ 1 ]-condition_type exp = `ZPI1` ).

  ENDMETHOD.

  METHOD items_are_nested.

    DATA(ls_request) = parse( full_body( ) ).
    DATA(lt_item)    = ls_request-orders[ 1 ]-items.

    cl_abap_unit_assert=>assert_equals( act = lines( lt_item ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 2 ]-material_number exp = `100000178` ).
    cl_abap_unit_assert=>assert_equals( act = lt_item[ 2 ]-sales_unit      exp = `KAR` ).

  ENDMETHOD.

  METHOD item_pricing_is_nested.

    " สามชั้น: order → item → pricing · ชั้นที่ลึกที่สุดที่ contract ใช้
    DATA(ls_request)  = parse( full_body( ) ).
    DATA(lt_pricing)  = ls_request-orders[ 1 ]-items[ 1 ]-pricings.

    cl_abap_unit_assert=>assert_equals( act = lines( lt_pricing ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_pricing[ 1 ]-condition_amount exp = `1070` ).

  ENDMETHOD.

  METHOD broken_json_raises.

    TRY.
        zcl_zsde002_json=>parse_json_request( EXPORTING iv_body    = `{ "RequestId": `
                                              IMPORTING es_request = DATA(ls_request) ).
        cl_abap_unit_assert=>fail( msg = `JSON ที่ปิดวงเล็บไม่ครบต้อง raise ไม่ใช่คืน structure ว่าง` ).

      CATCH zcx_zsde002_error.
        " ตามที่คาด — processor จะแปลงเป็น message 012
    ENDTRY.

  ENDMETHOD.

  METHOD unknown_field_is_ignored.

    " SBPA เพิ่ม field ที่เรายังไม่รู้จักเข้ามา ต้องไม่ทำให้ทั้ง request พัง
    DATA(lv_body) = `{ "RequestId": "R1", "SomethingNew": "x",` &&
                    `  "Orders": [ { "SfHeaderIdRef": "SF-001" } ] }`.

    cl_abap_unit_assert=>assert_equals( act = parse( lv_body )-request_id exp = `R1` ).

  ENDMETHOD.

  METHOD lower_case_name_is_lost.

    " ชื่อต้องเป็น PascalCase เป๊ะ — requestid ไม่ใช่ RequestId
    DATA(lv_body) = `{ "requestid": "R1", "Orders": [ { "SfHeaderIdRef": "SF-001" } ] }`.

    cl_abap_unit_assert=>assert_initial( act = parse( lv_body )-request_id
                                         msg = `ชื่อที่ไม่ใช่ PascalCase ต้องไม่ถูก map เข้า structure` ).

  ENDMETHOD.

ENDCLASS.
