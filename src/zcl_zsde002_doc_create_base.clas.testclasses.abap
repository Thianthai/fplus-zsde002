CLASS ltcl_condition_values DEFINITION DEFERRED.
CLASS zcl_zsde002_doc_create_base DEFINITION LOCAL FRIENDS ltcl_condition_values.


"! subclass เปล่าเพื่อให้ instantiate base ได้ — create ไม่ถูกเรียกในเทส
CLASS lcl_cut DEFINITION FINAL INHERITING FROM zcl_zsde002_doc_create_base.
  PUBLIC SECTION.
    METHODS zif_zsde002_doc_create~create REDEFINITION.
ENDCLASS.

CLASS lcl_cut IMPLEMENTATION.
  METHOD zif_zsde002_doc_create~create.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_condition_values DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA go_cut       TYPE REF TO zcl_zsde002_doc_create_base.
    DATA gt_calc_type TYPE zif_zsde002_master_data=>tt_condition_calc_type.

    METHODS setup.

    METHODS quantity_based_sends_all_four  FOR TESTING.
    METHODS fixed_amount_omits_quantity    FOR TESTING.
    METHODS percentage_sends_ratio_only    FOR TESTING.
    METHODS ratio_keeps_three_decimals     FOR TESTING.

ENDCLASS.


CLASS ltcl_condition_values IMPLEMENTATION.

  METHOD setup.
    go_cut = NEW lcl_cut( ).
    gt_calc_type = VALUE #( ( condition_type = 'ZPI1' calculation_type = 'C' )
                            ( condition_type = 'ZDI3' calculation_type = 'B' )
                            ( condition_type = 'ZZD1' calculation_type = 'A' ) ).
  ENDMETHOD.

  METHOD quantity_based_sends_all_four.

    DATA(ls_values) = go_cut->to_condition_values( iv_condition_type = 'ZPI1'
                                                   iv_amount         = `1070.00`
                                                   iv_currency       = `THB`
                                                   iv_pricing_unit   = `1`
                                                   iv_unit           = `KAR`
                                                   it_calc_type      = gt_calc_type ).

    cl_abap_unit_assert=>assert_true( ls_values-send_amount ).
    cl_abap_unit_assert=>assert_true( ls_values-send_currency ).
    cl_abap_unit_assert=>assert_true( ls_values-send_quantity ).
    cl_abap_unit_assert=>assert_false( ls_values-send_ratio ).
    cl_abap_unit_assert=>assert_equals( act = ls_values-rate_amount   exp = '1070.00' ).
    cl_abap_unit_assert=>assert_equals( act = ls_values-quantity      exp = '1.000' ).
    cl_abap_unit_assert=>assert_equals( act = ls_values-quantity_unit exp = 'KAR' ).

  ENDMETHOD.

  METHOD fixed_amount_omits_quantity.

    " ZDI3 คือตัวที่ RAP ปฏิเสธเพราะเราส่ง quantity ไป — ต้องไม่ส่งแม้ payload จะมีค่ามา
    DATA(ls_values) = go_cut->to_condition_values( iv_condition_type = 'ZDI3'
                                                   iv_amount         = `500.00`
                                                   iv_currency       = `THB`
                                                   iv_pricing_unit   = `1`
                                                   iv_unit           = `KAR`
                                                   it_calc_type      = gt_calc_type ).

    cl_abap_unit_assert=>assert_true( ls_values-send_amount ).
    cl_abap_unit_assert=>assert_true( ls_values-send_currency ).
    cl_abap_unit_assert=>assert_false( ls_values-send_quantity ).
    cl_abap_unit_assert=>assert_false( ls_values-send_ratio ).
    cl_abap_unit_assert=>assert_initial( ls_values-quantity ).
    cl_abap_unit_assert=>assert_initial( ls_values-quantity_unit ).

  ENDMETHOD.

  METHOD percentage_sends_ratio_only.

    DATA(ls_values) = go_cut->to_condition_values( iv_condition_type = 'ZZD1'
                                                   iv_amount         = `93.458`
                                                   iv_currency       = `THB`
                                                   iv_pricing_unit   = `1`
                                                   iv_unit           = `KAR`
                                                   it_calc_type      = gt_calc_type ).

    cl_abap_unit_assert=>assert_true( ls_values-send_ratio ).
    cl_abap_unit_assert=>assert_false( ls_values-send_amount ).
    cl_abap_unit_assert=>assert_false( ls_values-send_currency ).
    cl_abap_unit_assert=>assert_false( ls_values-send_quantity ).
    cl_abap_unit_assert=>assert_equals( act = ls_values-ratio_unit exp = '%' ).

  ENDMETHOD.

  METHOD ratio_keeps_three_decimals.

    " ZZD1 = 93.458 % — to_internal_amount มีแค่ 2 ตำแหน่งจะปัดเป็น 93.46 จึงต้องมี to_internal_ratio แยก
    cl_abap_unit_assert=>assert_equals( act = go_cut->to_internal_ratio( `93.458` )
                                        exp = '93.458' ).

  ENDMETHOD.

ENDCLASS.
