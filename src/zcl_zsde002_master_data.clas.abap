CLASS zcl_zsde002_master_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_zsde002_master_data.
ENDCLASS.



CLASS zcl_zsde002_master_data IMPLEMENTATION.

  METHOD zif_zsde002_master_data~read_process_type.

    SELECT FROM ztsd_prcs_ty
      FIELDS process_type,
             tran_type,
             sales_order_type,
             sales_organization,
             distribution_channel,
             division
      INTO TABLE @rt_result.

  ENDMETHOD.

  METHOD zif_zsde002_master_data~find_unknown_sales_area.

    DATA lr_sales_organization   TYPE RANGE OF zif_zsde002_master_data=>ty_sales_area-sales_organization.
    DATA lr_distribution_channel TYPE RANGE OF zif_zsde002_master_data=>ty_sales_area-distribution_channel.
    DATA lr_division             TYPE RANGE OF zif_zsde002_master_data=>ty_sales_area-division.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).

      IF NOT line_exists( lr_sales_organization[ low = <lfs_key>-sales_organization ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-sales_organization )
                     TO lr_sales_organization.
      ENDIF.

      IF NOT line_exists( lr_distribution_channel[ low = <lfs_key>-distribution_channel ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-distribution_channel )
                     TO lr_distribution_channel.
      ENDIF.

      IF NOT line_exists( lr_division[ low = <lfs_key>-division ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-division )
                     TO lr_division.
      ENDIF.

    ENDLOOP.

    SELECT FROM I_SalesArea
      FIELDS SalesOrganization,
             DistributionChannel,
             Division
      WHERE SalesOrganization   IN @lr_sales_organization
        AND DistributionChannel IN @lr_distribution_channel
        AND Division            IN @lr_division
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING <lfs_key>.
      IF NOT line_exists( lt_existing[ salesorganization   = <lfs_key>-sales_organization
                                       distributionchannel = <lfs_key>-distribution_channel
                                       division            = <lfs_key>-division ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_cust_sales_area.

    DATA lr_sales_organization   TYPE RANGE OF zif_zsde002_master_data=>ty_cust_sales_area-sales_organization.
    DATA lr_distribution_channel TYPE RANGE OF zif_zsde002_master_data=>ty_cust_sales_area-distribution_channel.
    DATA lr_division             TYPE RANGE OF zif_zsde002_master_data=>ty_cust_sales_area-division.
    DATA lr_customer             TYPE RANGE OF zif_zsde002_master_data=>ty_cust_sales_area-customer.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).

      IF NOT line_exists( lr_sales_organization[ low = <lfs_key>-sales_organization ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-sales_organization )
                     TO lr_sales_organization.
      ENDIF.

      IF NOT line_exists( lr_distribution_channel[ low = <lfs_key>-distribution_channel ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-distribution_channel )
                     TO lr_distribution_channel.
      ENDIF.

      IF NOT line_exists( lr_division[ low = <lfs_key>-division ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-division )
                     TO lr_division.
      ENDIF.

      IF NOT line_exists( lr_customer[ low = <lfs_key>-customer ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-customer )
                     TO lr_customer.
      ENDIF.

    ENDLOOP.

    SELECT FROM I_SalesArea AS sa
      INNER JOIN I_CustomerSalesArea AS csa
        ON  csa~SalesOrganization   = sa~SalesOrganization
        AND csa~DistributionChannel = sa~DistributionChannel
        AND csa~Division            = sa~Division
      FIELDS sa~SalesOrganization,
             sa~DistributionChannel,
             sa~Division,
             csa~Customer
      WHERE sa~SalesOrganization   IN @lr_sales_organization
        AND sa~DistributionChannel IN @lr_distribution_channel
        AND sa~Division            IN @lr_division
        AND csa~Customer           IN @lr_customer
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING <lfs_key>.
      IF NOT line_exists( lt_existing[ SalesOrganization   = <lfs_key>-sales_organization
                                       DistributionChannel = <lfs_key>-distribution_channel
                                       Division            = <lfs_key>-division
                                       Customer            = <lfs_key>-customer ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_sales_doc_type.

    DATA lr_sales_document_type TYPE RANGE OF zif_zsde002_master_data=>ty_sales_document_type.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    lr_sales_document_type = VALUE #( FOR <lfs_for> IN it_key
                                    ( sign = 'I' option = 'EQ' low = <lfs_for> ) ).

    SELECT FROM I_SalesDocumentType
      FIELDS SalesDocumentType
      WHERE SalesDocumentType IN @lr_sales_document_type
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).
      IF NOT line_exists( lt_existing[ SalesDocumentType = <lfs_key> ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_payment_terms.

    DATA lr_payment_terms TYPE RANGE OF zif_zsde002_master_data=>ty_payment_terms.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    lr_payment_terms = VALUE #( FOR <lfs_for> IN it_key
                              ( sign = 'I' option = 'EQ' low = <lfs_for> ) ).

    SELECT FROM I_PaymentTerms
      FIELDS PaymentTerms
      WHERE PaymentTerms IN @lr_payment_terms
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).
      IF NOT line_exists( lt_existing[ PaymentTerms = <lfs_key> ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_product.

    DATA lr_product TYPE RANGE OF zif_zsde002_master_data=>ty_product.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    lr_product = VALUE #( FOR <lfs_for> IN it_key
                        ( sign = 'I' option = 'EQ' low = <lfs_for> ) ).

    SELECT FROM I_Product
      FIELDS Product
      WHERE Product IN @lr_product
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).
      IF NOT line_exists( lt_existing[ Product = <lfs_key> ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_plant.

    DATA lr_plant TYPE RANGE OF zif_zsde002_master_data=>ty_plant.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    lr_plant = VALUE #( FOR <lfs_for> IN it_key
                      ( sign = 'I' option = 'EQ' low = <lfs_for> ) ).

    SELECT FROM I_Plant
      FIELDS Plant
      WHERE Plant IN @lr_plant
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).
      IF NOT line_exists( lt_existing[ Plant = <lfs_key> ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_storage_location.

    DATA lr_plant            TYPE RANGE OF zif_zsde002_master_data=>ty_storage_location-plant.
    DATA lr_storage_location TYPE RANGE OF zif_zsde002_master_data=>ty_storage_location-storage_location.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).

      IF NOT line_exists( lr_plant[ low = <lfs_key>-plant ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-plant )
                     TO lr_plant.
      ENDIF.

      IF NOT line_exists( lr_storage_location[ low = <lfs_key>-storage_location ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-storage_location )
                     TO lr_storage_location.
      ENDIF.

    ENDLOOP.

    SELECT FROM I_StorageLocation
      FIELDS Plant,
             StorageLocation
      WHERE Plant           IN @lr_plant
        AND StorageLocation IN @lr_storage_location
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING <lfs_key>.
      IF NOT line_exists( lt_existing[ Plant           = <lfs_key>-plant
                                       StorageLocation = <lfs_key>-storage_location ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_product_unit.

    DATA lr_product          TYPE RANGE OF zif_zsde002_master_data=>ty_product_unit-product.
    DATA lr_alternative_unit TYPE RANGE OF zif_zsde002_master_data=>ty_product_unit-alternative_unit.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).

      IF NOT line_exists( lr_product[ low = <lfs_key>-product ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-product )
                     TO lr_product.
      ENDIF.

      IF NOT line_exists( lr_alternative_unit[ low = <lfs_key>-alternative_unit ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-alternative_unit )
                     TO lr_alternative_unit.
      ENDIF.

    ENDLOOP.

    SELECT FROM I_ProductUnitsOfMeasure
      FIELDS Product,
             AlternativeUnit
      WHERE Product         IN @lr_product
        AND AlternativeUnit IN @lr_alternative_unit
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING <lfs_key>.
      IF NOT line_exists( lt_existing[ Product         = <lfs_key>-product
                                       AlternativeUnit = <lfs_key>-alternative_unit ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_condition_type.

    DATA lr_condition_type TYPE RANGE OF zif_zsde002_master_data=>ty_condition_type.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    lr_condition_type = VALUE #( FOR <lfs_for> IN it_key
                               ( sign = 'I' option = 'EQ' low = <lfs_for> ) ).

    SELECT FROM I_ConditionType
      FIELDS ConditionType
      WHERE ConditionType IN @lr_condition_type
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).
      IF NOT line_exists( lt_existing[ ConditionType = <lfs_key> ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_currency.

    DATA lr_currency TYPE RANGE OF zif_zsde002_master_data=>ty_currency.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    lr_currency = VALUE #( FOR <lfs_for> IN it_key
                         ( sign = 'I' option = 'EQ' low = <lfs_for> ) ).

    SELECT FROM I_Currency
      FIELDS Currency
      WHERE Currency IN @lr_currency
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).
      IF NOT line_exists( lt_existing[ Currency = <lfs_key> ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
