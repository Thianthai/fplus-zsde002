CLASS zcl_zsde002_spike_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .

  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS gc_request_id TYPE ztsd_e002_order-request_id VALUE 'SPIKE-LOG'.

    METHODS purge_all
      IMPORTING io_out TYPE REF TO if_oo_adt_classrun_out.

    METHODS create_test_data
      IMPORTING io_out TYPE REF TO if_oo_adt_classrun_out.

    METHODS verify
      IMPORTING io_out TYPE REF TO if_oo_adt_classrun_out.

    METHODS new_uuid
      RETURNING VALUE(rv_uuid) TYPE sysuuid_x16.

ENDCLASS.



CLASS zcl_zsde002_spike_log IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    purge_all( out ).
    create_test_data( out ).
    verify( out ).

  ENDMETHOD.


  METHOD new_uuid.

    TRY.
        rv_uuid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        CLEAR rv_uuid.
    ENDTRY.

  ENDMETHOD.


  METHOD purge_all.

    " the five tables hold nothing but spike data until the handler starts logging
    DELETE FROM ztsd_e002_itmprc.
    DELETE FROM ztsd_e002_ordprc.
    DELETE FROM ztsd_e002_ordmsg.
    DELETE FROM ztsd_e002_item.
    DELETE FROM ztsd_e002_order.

    COMMIT WORK.

    io_out->write( |--- all 5 tables purged ---| ).

  ENDMETHOD.


  METHOD create_test_data.

    DATA lt_order   TYPE STANDARD TABLE OF ztsd_e002_order.
    DATA lt_item    TYPE STANDARD TABLE OF ztsd_e002_item.
    DATA lt_ordprc  TYPE STANDARD TABLE OF ztsd_e002_ordprc.
    DATA lt_itmprc  TYPE STANDARD TABLE OF ztsd_e002_itmprc.
    DATA lt_ordmsg  TYPE STANDARD TABLE OF ztsd_e002_ordmsg.

    DATA lv_now     TYPE timestampl.
    DATA lv_item_no TYPE n LENGTH 6.

    GET TIME STAMP FIELD lv_now.

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

    DO 2 TIMES.

      DATA(lv_o)          = sy-index.
      DATA(lv_order_uuid) = new_uuid( ).

      APPEND VALUE #( order_uuid            = lv_order_uuid
                      request_id            = gc_request_id
                      request_body          = |\{ "sfHeaderIdRef": "SPIKE-{ lv_o }", "salesOrderType": "ZOR" \}|
                      sfheaderidref         = |SPIKE-{ lv_o }|
                      salesordertempid      = |TMP{ lv_o }|
                      processtype           = '01'
                      trantype              = 'N'
                      salesordertype        = 'ZOR'
                      salesorganization     = '1000'
                      distributionchannel   = '10'
                      division              = '00'
                      soldtoparty           = '0000001000'
                      shiptoparty           = '0000001000'
                      billtoparty           = '0000001000'
                      payer                 = '0000001000'
                      customerreference     = |PO-SPIKE-{ lv_o }|
                      documentdate          = '2026-08-30'
                      reqdeliverydate       = '2026-09-05'
                      shippingconditions    = '01'
                      currency              = 'THB'
                      paymentterm           = '0001'
                      salesordernumber      = COND #( WHEN lv_o = 1 THEN '0000004711' ELSE space )
                      order_status          = COND #( WHEN lv_o = 1 THEN 'S' ELSE 'E' )
                      created_by            = lv_user
                      created_at            = lv_now
                      last_changed_by       = lv_user
                      last_changed_at       = lv_now
                      local_last_changed_at = lv_now
                    ) TO lt_order.

      " ---------- header pricing ----------
      APPEND VALUE #( order_pricing_uuid     = new_uuid( )
                      order_uuid             = lv_order_uuid
                      conditiontype          = 'ZDI2'
                      conditionamount        = '100.00'
                      conditioncurrency      = 'THB'
                      conditionpricingunit   = '1'
                      conditionunitofmeasure = 'EA'
                      local_last_changed_at  = lv_now
                    ) TO lt_ordprc.

      APPEND VALUE #( order_pricing_uuid     = new_uuid( )
                      order_uuid             = lv_order_uuid
                      conditiontype          = 'ZDI3'
                      conditionamount        = '50.00'
                      conditioncurrency      = 'THB'
                      conditionpricingunit   = '1'
                      conditionunitofmeasure = 'EA'
                      local_last_changed_at  = lv_now
                    ) TO lt_ordprc.

      " ---------- messages ----------
      APPEND VALUE #( order_message_uuid    = new_uuid( )
                      order_uuid            = lv_order_uuid
                      msg_seq               = '0001'
                      area                  = 'HEADER'
                      status                = 'S'
                      message               = |Spike message 1 for order { lv_o }|
                      local_last_changed_at = lv_now
                    ) TO lt_ordmsg.

      APPEND VALUE #( order_message_uuid    = new_uuid( )
                      order_uuid            = lv_order_uuid
                      msg_seq               = '0002'
                      area                  = 'ITEM'
                      status                = 'W'
                      message               = |Spike message 2 for order { lv_o }|
                      local_last_changed_at = lv_now
                    ) TO lt_ordmsg.

      APPEND VALUE #( order_message_uuid    = new_uuid( )
                      order_uuid            = lv_order_uuid
                      msg_seq               = '0003'
                      area                  = 'COMMIT_HEADER'
                      status                = 'E'
                      message               = |Spike message 3 for order { lv_o }|
                      local_last_changed_at = lv_now
                    ) TO lt_ordmsg.

      " ---------- items ----------
      DO 2 TIMES.

        DATA(lv_i)         = sy-index.
        DATA(lv_item_uuid) = new_uuid( ).

        lv_item_no = lv_i * 10.

        APPEND VALUE #( item_uuid             = lv_item_uuid
                        order_uuid            = lv_order_uuid
                        item                  = lv_item_no
                        materialnumber        = |MAT-{ lv_o }{ lv_i }|
                        customermaterial      = |CMAT-{ lv_i }|
                        itemcategory          = 'ZTAN'
                        requestedquantity     = '10.000'
                        salesunit             = 'EA'
                        plant                 = '1000'
                        storagelocation       = '0001'
                        salestext             = |Spike sales text for item { lv_i }|
                        sfitemidref           = |SFITEM-{ lv_o }{ lv_i }|
                        local_last_changed_at = lv_now
                      ) TO lt_item.

        " ---------- item pricing : order_uuid filled directly, no RAP needed ----------
        APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                        item_uuid              = lv_item_uuid
                        order_uuid             = lv_order_uuid
                        conditiontype          = 'ZPI1'
                        conditionamount        = '250.00'
                        conditioncurrency      = 'THB'
                        conditionpricingunit   = '1'
                        conditionunitofmeasure = 'EA'
                        local_last_changed_at  = lv_now
                      ) TO lt_itmprc.

        APPEND VALUE #( item_pricing_uuid      = new_uuid( )
                        item_uuid              = lv_item_uuid
                        order_uuid             = lv_order_uuid
                        conditiontype          = 'ZDI1'
                        conditionamount        = '25.00'
                        conditioncurrency      = 'THB'
                        conditionpricingunit   = '1'
                        conditionunitofmeasure = 'EA'
                        local_last_changed_at  = lv_now
                      ) TO lt_itmprc.

      ENDDO.
    ENDDO.

    INSERT ztsd_e002_order  FROM TABLE @lt_order.
    io_out->write( |INSERT order  : sy-subrc { sy-subrc }, { sy-dbcnt } row(s)| ).

    INSERT ztsd_e002_item   FROM TABLE @lt_item.
    io_out->write( |INSERT item   : sy-subrc { sy-subrc }, { sy-dbcnt } row(s)| ).

    INSERT ztsd_e002_ordprc FROM TABLE @lt_ordprc.
    io_out->write( |INSERT ordprc : sy-subrc { sy-subrc }, { sy-dbcnt } row(s)| ).

    INSERT ztsd_e002_itmprc FROM TABLE @lt_itmprc.
    io_out->write( |INSERT itmprc : sy-subrc { sy-subrc }, { sy-dbcnt } row(s)| ).

    INSERT ztsd_e002_ordmsg FROM TABLE @lt_ordmsg.
    io_out->write( |INSERT ordmsg : sy-subrc { sy-subrc }, { sy-dbcnt } row(s)| ).

    COMMIT WORK.

  ENDMETHOD.


  METHOD verify.

    SELECT COUNT(*) FROM ztsd_e002_order
      WHERE request_id = @gc_request_id
      INTO @DATA(lv_order_count).

    SELECT COUNT(*) FROM ztsd_e002_item  AS i
      INNER JOIN ztsd_e002_order AS o ON o~order_uuid = i~order_uuid
      WHERE o~request_id = @gc_request_id
      INTO @DATA(lv_item_count).

    SELECT COUNT(*) FROM ztsd_e002_ordprc AS p
      INNER JOIN ztsd_e002_order AS o ON o~order_uuid = p~order_uuid
      WHERE o~request_id = @gc_request_id
      INTO @DATA(lv_ordprc_count).

    SELECT COUNT(*) FROM ztsd_e002_ordmsg AS m
      INNER JOIN ztsd_e002_order AS o ON o~order_uuid = m~order_uuid
      WHERE o~request_id = @gc_request_id
      INTO @DATA(lv_ordmsg_count).

    SELECT COUNT(*) FROM ztsd_e002_itmprc AS ip
      INNER JOIN ztsd_e002_item  AS i ON i~item_uuid  = ip~item_uuid
      INNER JOIN ztsd_e002_order AS o ON o~order_uuid = i~order_uuid
      WHERE o~request_id = @gc_request_id
      INTO @DATA(lv_itmprc_count).

    DATA lv_initial_uuid TYPE sysuuid_x16.

    SELECT COUNT(*) FROM ztsd_e002_itmprc
      WHERE order_uuid = @lv_initial_uuid
      INTO @DATA(lv_itmprc_orphan).

    io_out->write( |--- VERIFY ---| ).
    io_out->write( |ZTSD_E002_ORDER  : { lv_order_count }  (expected 2)| ).
    io_out->write( |ZTSD_E002_ITEM   : { lv_item_count }  (expected 4)| ).
    io_out->write( |ZTSD_E002_ORDPRC : { lv_ordprc_count }  (expected 4)| ).
    io_out->write( |ZTSD_E002_ORDMSG : { lv_ordmsg_count }  (expected 6)| ).
    io_out->write( |ZTSD_E002_ITMPRC : { lv_itmprc_count }  (expected 8)| ).
    io_out->write( |ITMPRC rows with empty ORDER_UUID : { lv_itmprc_orphan }  (expected 0)| ).

  ENDMETHOD.

ENDCLASS.
