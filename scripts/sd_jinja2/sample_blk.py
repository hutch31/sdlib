import sd_jinja2 as sdjj

intf_data = sdjj.sdIntf(name="data", sigs=[["field0", "logic", 512]])
intf_data.add_sig(name="field1", t="sample_pkg::magic_type_sv", sz=4)
intf_data.add_sig(name="field2", t="logic")
intf_data.set_description("""           This is a simple srdy/drdy interface
    with several fields of data, and there is no particular relationship between
    these fields. I know, I'm just making this really verbose for the sake of
    being very verbose.
    """)
