use fonky::types::register_singletons;
use ki18n::klocalizedcontext::KLocalizedContext;
use qmetaobject::prelude::*;
use qmetaobject::QUrl;

use fonky::types::*;

// Qt Resource File definition
qrc!(root_qml,
    "" {
        "qml/main.qml" as "main.qml",
        "qml/pages/FontsPage.qml" as "pages/FontsPage.qml",
        "qml/pages/FontInfoPage.qml" as "pages/FontInfoPage.qml",
        "qml/pages/AboutPage.qml" as "pages/AboutPage.qml",
        "qml/lib/FontCard.qml" as "lib/FontCard.qml",
    }
);

fn main() {
    qmeta_async::run(|| {
        qmetaobject::log::init_qt_to_rust();
        env_logger::init();
        log::info!("Starting Application");

        root_qml();

        register_singletons();
        register_types();

        qmetaobject::qtquickcontrols2::QQuickStyle::set_style("org.kde.desktop");

        let mut engine = QmlEngine::new();
        KLocalizedContext::init_from_engine(&engine);
        engine.load_url(QUrl::from(QString::from("qrc:///main.qml")));
        engine.exec();
    })
    .expect("running application");
}
