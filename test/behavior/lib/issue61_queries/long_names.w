pub type MonumentallyVerboseCarrierForCompilerOwnedStringStability {
    extraordinarily_verbose_lookup_field_name_that_must_remain_stable: HashMap[str, i32],
    extraordinarily_verbose_alias_field_name_that_must_remain_stable: Option[str],
    extraordinarily_verbose_numbers_field_name_that_must_remain_stable: Vec[i32],
}

pub fn make_monumentally_verbose_carrier_for_compiler_owned_string_stability() -> MonumentallyVerboseCarrierForCompilerOwnedStringStability:
    let lookup = HashMap[str, i32].new()
    lookup.insert("alpha_alpha_alpha_alpha_alpha_alpha_alpha", 9)
    lookup.insert("beta_beta_beta_beta_beta_beta_beta", 12)

    let numbers: Vec[i32] = Vec.new()
    numbers.push(1)
    numbers.push(2)
    numbers.push(3)

    MonumentallyVerboseCarrierForCompilerOwnedStringStability {
        extraordinarily_verbose_lookup_field_name_that_must_remain_stable: lookup,
        extraordinarily_verbose_alias_field_name_that_must_remain_stable: Some("  AURORA_AURORA  "),
        extraordinarily_verbose_numbers_field_name_that_must_remain_stable: numbers,
    }

pub fn long_name_score() -> i32:
    let carrier = make_monumentally_verbose_carrier_for_compiler_owned_string_stability()
    let lowered = carrier.extraordinarily_verbose_alias_field_name_that_must_remain_stable.unwrap().trim().to_lower()
    let scratch = HashMap[str, i32].new()
    scratch.insert("soon_removed_soon_removed_soon_removed", 99)
    scratch.remove("soon_removed_soon_removed_soon_removed")

    var total = carrier.extraordinarily_verbose_lookup_field_name_that_must_remain_stable.len() as i32
    total = total + carrier.extraordinarily_verbose_numbers_field_name_that_must_remain_stable.len() as i32
    if carrier.extraordinarily_verbose_lookup_field_name_that_must_remain_stable.contains("beta_beta_beta_beta_beta_beta_beta"):
        total = total + 5
    if lowered.contains("aurora"):
        total = total + 4
    if lowered.starts_with("aurora"):
        total = total + 6
    if lowered.ends_with("aurora"):
        total = total + 7
    total = total + carrier.extraordinarily_verbose_lookup_field_name_that_must_remain_stable.get("beta_beta_beta_beta_beta_beta_beta").unwrap()
    total = total + carrier.extraordinarily_verbose_lookup_field_name_that_must_remain_stable.get("alpha_alpha_alpha_alpha_alpha_alpha_alpha").unwrap()
    total
