use std::fs;
use std::fs::DirEntry;
use std::future::*;
use std::io;
use std::path::PathBuf;
use std::task::*;

use qmetaobject::prelude::*;
use qmetaobject::{QJsonArray, QJsonObject, QString};
use tokio;
use tokio::sync::Mutex;
use ureq;

#[derive(Clone)]
struct InstallTask {
    family_name: String,
    variant_names: Vec<String>,
    urls: Vec<String>,
    path: String,
}

impl InstallTask {
    pub fn new(
        family_name: String,
        variant_names: Vec<String>,
        urls: Vec<String>,
        path: String,
    ) -> Self {
        Self {
            family_name,
            variant_names,
            urls,
            path,
        }
    }
}

impl Future for InstallTask {
    type Output = Result<(), Box<dyn std::error::Error>>;

    fn poll(
        self: std::pin::Pin<&mut Self>,
        _cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Self::Output> {
        for (i, variant_name) in self.variant_names.clone().into_iter().enumerate() {
            // Get the response and turn it into a reader
            let url = &self.urls.get(i).unwrap();
            let response = ureq::get(url).call()?;
            let mut downloaded_file = response.into_reader();

            // Setup the destination path
            let mut destination_path = PathBuf::new();
            if self.path.starts_with("~") {
                destination_path = dirs::home_dir().ok_or_else(|| {
                    std::io::Error::new(std::io::ErrorKind::Other, "Can't locate home directory.")
                })?;
            }
            destination_path.push(self.path.replace("~/", ""));
            if self.path.ends_with(".fonts") {
                destination_path.push(
                    &self.family_name.chars().collect::<Vec<char>>()[0]
                        .to_string()
                        .to_lowercase(),
                );
            }
            fs::create_dir_all(&destination_path)?;
            destination_path.push(format!("{} {}.ttf", &self.family_name, variant_name));

            println!("{:#?}", destination_path);

            // Create a file at the destination path
            let mut out = fs::File::create(destination_path)?;

            // Copy the response contents to the file
            io::copy(&mut downloaded_file, &mut out)?;
        }

        Poll::Ready(Ok(()))
    }
}

#[derive(Clone)]
struct RemoveTask {
    name: String,
}

impl RemoveTask {
    pub fn new(name: String) -> Self {
        Self { name }
    }
}

impl Future for RemoveTask {
    type Output = Result<(), Box<dyn std::error::Error>>;

    fn poll(self: std::pin::Pin<&mut Self>, _cx: &mut Context<'_>) -> Poll<Self::Output> {
        // Setup the fonts path
        let mut fonts_path = dirs::home_dir().ok_or_else(|| {
            std::io::Error::new(std::io::ErrorKind::Other, "Can't locate home directory.")
        })?;
        fonts_path.push(".fonts");
        fonts_path.push(
            self.name.chars().collect::<Vec<char>>()[0]
                .to_string()
                .to_lowercase(),
        );

        // Get the font family files
        let font_files = fs::read_dir(fonts_path)?
            .into_iter()
            .filter_map(|f| {
                f.as_ref()
                    .ok()?
                    .file_name()
                    .into_string()
                    .ok()?
                    .to_uppercase()
                    .contains(&self.name.to_uppercase())
                    .then_some(f)
            })
            .collect::<Vec<Result<DirEntry, _>>>();

        // Remove the files
        for file in font_files {
            fs::remove_file(file?.path())?;
        }

        Poll::Ready(Ok(()))
    }
}

#[derive(QObject, Default)]
pub struct TaskQueue {
    base: qt_base_class!(trait QObject),
    tasks: qt_property!(QJsonArray; NOTIFY tasks_changed),
    tasks_changed: qt_signal!(),
    install_font_family: qt_method!(
        fn install_font_family(
            &'static mut self,
            index: u32,
            family_name: QString,
            variant_names: QString,
            urls: QString,
        ) {
            // Call the actual function in a different thread
            qmeta_async::with_executor(|| {
                tokio::task::spawn(async move {
                    let task = InstallTask::new(
                        family_name.to_string(),
                        variant_names
                            .to_string()
                            .split(";")
                            .map(|e| e.to_string())
                            .collect(),
                        urls.to_string().split(";").map(|e| e.to_string()).collect(),
                        "~/.fonts".to_string(),
                    );

                    Self::handle_task(
                        Mutex::new(self),
                        Box::new(task),
                        index,
                        "install".to_string(),
                        family_name.to_string(),
                    )
                    .await;
                });
            });
        }
    ),
    remove_font_family: qt_method!(
        fn remove_font_family(&'static mut self, index: u32, name: QString) {
            // Call the actual function in a different thread
            qmeta_async::with_executor(|| {
                tokio::task::spawn(async move {
                    let task = RemoveTask::new(name.to_string());

                    Self::handle_task(
                        Mutex::new(self),
                        Box::new(task),
                        index,
                        "remove".to_string(),
                        name.to_string(),
                    )
                    .await;
                });
            });
        }
    ),
    save_font_family: qt_method!(
        fn save_font_family(
            &'static mut self,
            index: u32,
            family_name: QString,
            variant_names: QString,
            urls: QString,
            path: QString,
        ) {
            qmeta_async::with_executor(|| {
                tokio::task::spawn(async move {
                    let task = InstallTask::new(
                        family_name.to_string(),
                        variant_names
                            .to_string()
                            .split(";")
                            .map(|e| e.to_string())
                            .collect(),
                        urls.to_string().split(";").map(|e| e.to_string()).collect(),
                        path.to_string(),
                    );

                    Self::handle_task(
                        Mutex::new(self),
                        Box::new(task),
                        index,
                        "save".to_string(),
                        family_name.to_string(),
                    )
                    .await;
                });
            });
        }
    ),
}

impl TaskQueue {
    async fn handle_task(
        this: Mutex<&'static mut Self>,
        task: Box<
            dyn Send + Sync + Unpin + Future<Output = Result<(), Box<dyn std::error::Error>>>,
        >,
        index: u32,
        task_name: String,
        name: String,
    ) {
        // Acquire the Mutex lock for "this" (which is actually self)
        let mut this_locked = this.lock().await;

        // Construct the JSON object for the task
        let mut task_json = QJsonObject::default();
        task_json.insert("card_index", QString::from(index.to_string()).into());
        task_json.insert("task", QString::from(task_name).into());
        task_json.insert("name", QString::from(name).into());
        task_json.insert("status", QString::from("pending").into());
        this_locked.tasks.push(task_json.into());
        this_locked.tasks_changed();

        let task_index = this_locked.tasks.len() - 1;

        let task_result = task.await;

        // Write the result to the task JSON object
        let mut json: QJsonObject = this_locked.tasks.at(task_index).into();
        if task_result.is_ok() {
            json.insert("status", QString::from("done").into());
        } else {
            json.insert("status", QString::from("failed").into());
        }
        this_locked.tasks.remove_at(task_index);
        this_locked.tasks.insert(task_index, json.into());
        this_locked.tasks_changed();
    }
}

unsafe impl Send for TaskQueue {}
unsafe impl Sync for TaskQueue {}
