use super::providers::{SystemFontsProvider, WebFontsProvider};
use super::tasks::TaskQueue;
use cstr::cstr;
use qmetaobject::{qml_register_singleton_type, qml_register_type, qt_method};

pub fn register_singletons() {
    qml_register_singleton_type::<SystemFontsProvider>(
        cstr!("SystemFontsProvider"),
        1,
        0,
        cstr!("SystemFontsProvider"),
    );
    qml_register_singleton_type::<WebFontsProvider>(
        cstr!("WebFontsProvider"),
        1,
        0,
        cstr!("WebFontsProvider"),
    );
}

pub fn register_types() {
    qml_register_type::<TaskQueue>(cstr!("TaskQueue"), 1, 0, cstr!("TaskQueue"));
}
