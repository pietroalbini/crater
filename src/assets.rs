use errors::*;
use mime::{self, Mime};
use serde::Serialize;
use std::borrow::Cow;
use std::collections::HashMap;
use std::path::PathBuf;
use tera::Tera;

#[cfg(not(debug_assertions))]
lazy_static! {
    static ref TERA_CACHE: Tera = match build_tera_cache() {
        Ok(tera) => tera,
        Err(err) => {
            ::util::report_error(&err);
            ::std::process::exit(1);
        }
    };
}

macro_rules! load_files {
    (templates: [$($template:expr,)*], assets: [$($asset:expr => $mime:expr,)*],) => {
        lazy_static! {
            static ref ASSETS: HashMap<&'static str, Asset> = {
                let mut assets = HashMap::new();
                $(
                    let content = load_files!(_content concat!("assets/", $asset));
                    assets.insert($asset, Asset {
                        content,
                        mime: $mime,
                    });
                )*
                assets
            };

            static ref TEMPLATES: HashMap<&'static str, FileContent> = {
                let mut templates = HashMap::new();
                $(templates.insert($template, load_files!(_content concat!("templates/", $template)));)*
                templates
            };
        }
    };

    (_content $file:expr) => {{
        #[cfg(debug_assertions)]
        {
            warn!("loaded dynamic asset (use release builds to statically bundle it): {}", $file);
            FileContent::Dynamic($file.into())
        }

        #[cfg(not(debug_assertions))]
        {
            FileContent::Static(include_bytes!(concat!("../", $file)))
        }
    }};
}

load_files! {
    templates: [
        "macros.html",
        "layout.html",

        "agents.html",

        "queue.html",
        "experiment.html",

        "404.html",
        "500.html",

        "report.html",
    ],
    assets: [
        "ui.css" => mime::TEXT_CSS,

        "report.css" => mime::TEXT_CSS,
        "report.js" => mime::TEXT_JAVASCRIPT,

        "favicon.ico" => "image/x-icon".parse().unwrap(),
    ],
}

enum FileContent {
    #[cfg_attr(debug_assertions, allow(dead_code))]
    Static(&'static [u8]),
    #[cfg_attr(not(debug_assertions), allow(dead_code))]
    Dynamic(PathBuf),
}

impl FileContent {
    fn load(&self) -> Result<Cow<[u8]>> {
        Ok(match *self {
            FileContent::Static(content) => Cow::Borrowed(content),
            FileContent::Dynamic(ref path) => Cow::Owned(::std::fs::read(path)?),
        })
    }
}

pub struct Asset {
    content: FileContent,
    mime: Mime,
}

impl Asset {
    pub fn content(&self) -> Result<Cow<[u8]>> {
        self.content.load()
    }

    pub fn mime(&self) -> &Mime {
        &self.mime
    }
}

pub fn load(name: &str) -> Result<&Asset> {
    if let Some(ref asset) = ASSETS.get(name) {
        Ok(asset)
    } else {
        bail!(
            "unknown static file (did you add it to src/assets.rs?): {}",
            name
        );
    }
}

fn build_tera_cache() -> Result<Tera> {
    let mut templates = Vec::new();
    for (name, content) in TEMPLATES.iter() {
        templates.push((*name, String::from_utf8(content.load()?.into_owned())?));
    }

    let to_add = templates
        .iter()
        .map(|(n, c)| (*n, c as &str))
        .collect::<Vec<_>>();

    let mut tera = Tera::default();
    tera.add_raw_templates(to_add)?;
    Ok(tera)
}

#[allow(unused_variables)]
pub fn render_template<C: Serialize>(name: &str, context: &C) -> Result<String> {
    // On debug builds the cache is rebuilt every time to pick up changed templates
    let tera_owned: Tera;
    let tera;

    #[cfg(debug_assertions)]
    {
        tera_owned = build_tera_cache()?;
        tera = &tera_owned;
    }

    #[cfg(not(debug_assertions))]
    {
        tera = &TERA_CACHE;
    }

    Ok(tera.render(name, context)?)
}
