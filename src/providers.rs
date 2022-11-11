use std::fs;
use std::io::Read;

use font_kit::source::SystemSource;
use qmetaobject::prelude::*;
use qmetaobject::{QSingletonInit, QString, QStringList};
use ttf_parser::Face;
use walkdir::WalkDir;

trait Provider {
    type Output;

    fn provide(&self) -> Self::Output;
}

#[derive(QObject, Default)]
pub struct SystemFontsProvider {
    base: qt_base_class!(trait QObject),
    get_families: qt_method!(
        fn get_families(&self) -> QStringList {
            self.provide().unwrap_or(QStringList::new())
        }
    ),
}

impl Provider for SystemFontsProvider {
    type Output = Option<QStringList>;

    fn provide(&self) -> Self::Output {
        /*
        let families = SystemSource::new()
            .all_families()
            .or::<Vec<String>>(Ok(Vec::new()));
        QStringList::from(families.unwrap())
        */

        let mut families: Vec<String> = Vec::new();
        let mut search_dir = dirs::home_dir()?;
        search_dir.push(".fonts");
        let search_entries = WalkDir::new(search_dir).into_iter().collect::<Vec<_>>();

        for entry in search_entries {
            if let Some(entry_value) = entry.ok() {
                if let Some(bytes) = fs::read(entry_value.path()).ok() {
                    if let Some(face) = Face::parse(&bytes, 0).ok() {
                        let family_name = face
                            .names()
                            .into_iter()
                            .find(|name| {
                                name.name_id == ttf_parser::name_id::FAMILY && name.is_unicode()
                            })
                            .and_then(|name| name.to_string());

                        if let Some(family_name) = family_name {
                            if !families.contains(&family_name) {
                                families.push(family_name);
                            }
                        }
                    }
                }
            }
        }

        Some(QStringList::from(families))
    }
}

impl QSingletonInit for SystemFontsProvider {
    fn init(&mut self) {}
}

#[derive(QObject, Default)]
pub struct WebFontsProvider {
    base: qt_base_class!(trait QObject),
    get_json: qt_method!(
        fn get_json(&self) -> QString {
            self.provide()
        }
    ),
}

impl Provider for WebFontsProvider {
    type Output = QString;

    fn provide(&self) -> Self::Output {
        QString::from(std::include_str!("webfonts.json"))
    }
}

impl QSingletonInit for WebFontsProvider {
    fn init(&mut self) {}
}
