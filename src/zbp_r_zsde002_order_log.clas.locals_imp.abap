CLASS lhc_OrderLog DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR OrderLog RESULT result.

ENDCLASS.

CLASS lhc_OrderLog IMPLEMENTATION.

  METHOD get_global_authorizations.

    " Log is written by ZCL_ZSDE002_HANDLER only, the UI projection is read-only
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
