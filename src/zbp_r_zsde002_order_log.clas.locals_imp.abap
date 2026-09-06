CLASS lhc_OrderLog DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR OrderLog RESULT result.

ENDCLASS.

CLASS lhc_OrderLog IMPLEMENTATION.

  METHOD get_global_authorizations.

    " Log rows are written by ZCL_ZSDE002_PROCESSOR with direct INSERT.
    " This projection is read-only: the monitor displays, it never edits.
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
