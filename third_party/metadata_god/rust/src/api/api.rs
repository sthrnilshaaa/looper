use anyhow::{anyhow, Result};
use lofty::{
    config::WriteOptions,
    file::{AudioFile, TaggedFile, TaggedFileExt},
    picture::{MimeType, PictureType},
    properties::FileProperties,
    tag::{Accessor, ItemKey, ItemValue, Tag, TagExt, TagItem},
};

#[derive(Debug)]
pub struct Picture {
    /// The picture's MIME type.
    pub mime_type: String,
    /// The image data.
    pub data: Vec<u8>,
}

#[derive(Debug)]
pub struct Metadata {
    pub title: Option<String>,
    pub duration_ms: Option<f64>,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub album_artist: Option<String>,
    pub track_number: Option<u16>,
    pub track_total: Option<u16>,
    pub disc_number: Option<u16>,
    pub disc_total: Option<u16>,
    pub year: Option<i32>,
    pub genre: Option<String>,
    pub picture: Option<Picture>,
    pub file_size: Option<u64>,
}

pub fn read_metadata(file: String) -> Result<Metadata> {
    let (tagged_file, tag) = get_tag_for_file(&file)?;
    let cover = tag
        .get_picture_type(PictureType::CoverFront)
        .or(tag.pictures().first());
    Ok(Metadata {
        title: tag.title().and_then(|s| Some(s.to_string())),
        duration_ms: Some(tagged_file.properties().duration().as_millis() as f64),
        album: tag.album().and_then(|s| Some(s.to_string())),
        album_artist: tag
            .get(&ItemKey::AlbumArtist)
            .and_then(|s| match s.value() {
                ItemValue::Text(t) => Some(t.to_string()),
                _ => None,
            }),
        artist: tag.artist().and_then(|s| Some(s.to_string())),
        track_number: tag.track().map(|f| f as u16),
        track_total: tag.track_total().map(|f| f as u16),
        disc_number: tag.disk().map(|f| f as u16),
        disc_total: tag.disk_total().map(|f| f as u16),
        year: tag.year().map(|f| f as i32),
        genre: tag.genre().and_then(|s| Some(s.to_string())),
        picture: (match cover {
            Some(cover) => Some(Picture {
                mime_type: match cover.mime_type() {
                    Some(mime_type) => mime_type.to_string(),
                    None => "image/jpeg".to_string(),
                },
                data: cover.data().to_vec(),
            }),
            None => None,
        }),
        file_size: Some(21231_u64),
    })
}

pub fn write_metadata(file: String, metadata: Metadata) -> Result<()> {
    let (_tagged_file, mut tag) = open_or_create_tag_for_file(&file)?;

    if metadata.title.is_some() {
        tag.set_title(metadata.title.unwrap());
    }
    if metadata.album.is_some() {
        tag.set_album(metadata.album.unwrap());
    }
    if metadata.album_artist.is_some() {
        tag.insert(TagItem::new(
            ItemKey::AlbumArtist,
            ItemValue::Text(metadata.album_artist.unwrap()),
        ));
    }
    if metadata.artist.is_some() {
        tag.set_artist(metadata.artist.unwrap());
    }
    if metadata.track_number.is_some() {
        tag.set_track(metadata.track_number.unwrap() as u32);
    }
    if metadata.track_total.is_some() {
        tag.set_track_total(metadata.track_total.unwrap() as u32);
    }
    if metadata.disc_number.is_some() {
        tag.set_disk(metadata.disc_number.unwrap() as u32);
    }
    if metadata.disc_total.is_some() {
        tag.set_disk_total(metadata.disc_total.unwrap() as u32);
    }
    if metadata.year.is_some() {
        tag.set_year(metadata.year.unwrap() as u32);
    }
    if metadata.genre.is_some() {
        tag.set_genre(metadata.genre.unwrap());
    }
    if metadata.picture.is_some() {
        let image = metadata.picture.unwrap();
        tag.push_picture(lofty::picture::Picture::new_unchecked(
            PictureType::CoverFront,
            Some(MimeType::from_str(&image.mime_type)),
            None,
            image.data,
        ));
    }

    tag.save_to_path(&file, WriteOptions::default())?;
    Ok(())
}

fn open_or_create_tag_for_file(file: &str) -> Result<(TaggedFile, Tag)> {
    let mut tagged_file = match lofty::read_from_path(file) {
        Ok(tagged_file) => tagged_file,
        _ => {
            let prob = lofty::probe::Probe::open(file)?;

            if prob.file_type().is_none() {
                return Err(anyhow!("File type could not be determined"));
            }

            TaggedFile::new(prob.file_type().unwrap(), FileProperties::default(), vec![])
        }
    };

    let tag = match tagged_file.primary_tag_mut() {
        Some(primary_tag) => primary_tag,
        None => {
            if let Some(first_tag) = tagged_file.first_tag_mut() {
                first_tag
            } else {
                let tag_type = tagged_file.primary_tag_type();

                eprintln!("WARN: No tags found, creating a new tag of type `{tag_type:?}`");
                tagged_file.insert_tag(Tag::new(tag_type));

                tagged_file.primary_tag_mut().unwrap()
            }
        }
    }
    .to_owned();
    Ok((tagged_file, tag))
}

fn get_tag_for_file(file: &str) -> Result<(TaggedFile, Tag)> {
    let mut tagged_file = lofty::read_from_path(file)?;

    let tag = match tagged_file.primary_tag_mut() {
        Some(primary_tag) => primary_tag,
        None => {
            if let Some(first_tag) = tagged_file.first_tag_mut() {
                first_tag
            } else {
                let tag_type = tagged_file.primary_tag_type();

                eprintln!("WARN: No tags found, creating a new tag of type `{tag_type:?}`");
                tagged_file.insert_tag(Tag::new(tag_type));

                tagged_file.primary_tag_mut().unwrap()
            }
        }
    }
    .to_owned();
    Ok((tagged_file, tag))
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
