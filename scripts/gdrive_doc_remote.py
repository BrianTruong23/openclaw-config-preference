#!/usr/bin/env python3
import argparse
import json
import mimetypes
from pathlib import Path

from google.auth.transport.requests import Request
from google.auth.exceptions import RefreshError
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

CONFIG_DIR = Path("/root/.config/openclaw/google-drive")
CLIENT_SECRETS = CONFIG_DIR / "client_secrets.json"
TOKEN_FILE = CONFIG_DIR / "token.json"
DEFAULT_FOLDER_PATH = "/My Drive/spring_2026/OpenClaw"
SCOPES = [
    "https://www.googleapis.com/auth/drive",
    "https://www.googleapis.com/auth/documents",
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/presentations",
]


def load_credentials():
    creds = None
    if TOKEN_FILE.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
    if creds and creds.expired and creds.refresh_token:
        try:
            creds.refresh(Request())
        except RefreshError as exc:
            raise SystemExit(
                "Google Drive token refresh failed. Reauthorize with all Google Workspace scopes and replace "
                f"{TOKEN_FILE}. Original error: {exc}"
            ) from exc
        TOKEN_FILE.write_text(creds.to_json())
    if not creds or not creds.valid:
        raise SystemExit("Google Drive is not authorized yet. Run: gdrive-doc auth --port 8091")
    return creds


def drive_service(creds):
    return build("drive", "v3", credentials=creds)


def docs_service(creds):
    return build("docs", "v1", credentials=creds)


def sheets_service(creds):
    return build("sheets", "v4", credentials=creds)


def slides_service(creds):
    return build("slides", "v1", credentials=creds)


def find_child_folder(service, parent_id, name):
    q = (
        f"mimeType='application/vnd.google-apps.folder' and trashed=false "
        f"and name={json.dumps(name)} and '{parent_id}' in parents"
    )
    resp = service.files().list(q=q, spaces="drive", fields="files(id,name)", pageSize=10).execute()
    files = resp.get("files", [])
    return files[0]["id"] if files else None


def create_folder(service, parent_id, name):
    meta = {
        "name": name,
        "mimeType": "application/vnd.google-apps.folder",
        "parents": [parent_id],
    }
    created = service.files().create(body=meta, fields="id,name").execute()
    return created["id"]


def ensure_folder_path(service, folder_path):
    raw_path = folder_path.strip() if folder_path else ""
    path = raw_path or DEFAULT_FOLDER_PATH
    if not path:
        raise SystemExit("Folder path is required")
    if not path.startswith("/"):
        raise SystemExit("Folder path must start with /My Drive/...")
    parts = [p for p in path.split("/") if p]
    if not parts or parts[0] != "My Drive":
        raise SystemExit("Folder path must start with /My Drive")
    parent_id = "root"
    for name in parts[1:]:
        child_id = find_child_folder(service, parent_id, name)
        if not child_id:
            child_id = create_folder(service, parent_id, name)
        parent_id = child_id
    return parent_id


def move_to_folder(drive, file_id, folder_id):
    meta = drive.files().get(fileId=file_id, fields="parents,webViewLink").execute()
    old_parents = ",".join(meta.get("parents", []))
    updated = drive.files().update(
        fileId=file_id,
        addParents=folder_id,
        removeParents=old_parents,
        fields="id,parents,webViewLink",
    ).execute()
    return updated.get("webViewLink")


def cmd_auth(args):
    if not CLIENT_SECRETS.exists():
        raise SystemExit(f"Missing client secrets file: {CLIENT_SECRETS}")
    flow = InstalledAppFlow.from_client_secrets_file(str(CLIENT_SECRETS), SCOPES)
    creds = flow.run_local_server(
        host="127.0.0.1",
        port=args.port,
        open_browser=False,
        access_type="offline",
        prompt="consent",
    )
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    TOKEN_FILE.write_text(creds.to_json())
    print(f"Authorized successfully. Token stored at {TOKEN_FILE}")


def cmd_ensure_folder(args):
    creds = load_credentials()
    folder_id = ensure_folder_path(drive_service(creds), args.folder_path)
    print(json.dumps({"folderPath": args.folder_path or DEFAULT_FOLDER_PATH, "folderId": folder_id}, indent=2))


def cmd_status(args):
    status = {
        "clientSecretsPresent": CLIENT_SECRETS.exists(),
        "tokenPresent": TOKEN_FILE.exists(),
        "defaultFolderPath": DEFAULT_FOLDER_PATH,
    }
    if not status["clientSecretsPresent"]:
        print(json.dumps(status, indent=2))
        raise SystemExit(1)
    try:
        creds = load_credentials()
        drive = drive_service(creds)
        folder_id = ensure_folder_path(drive, DEFAULT_FOLDER_PATH if args.resolve_default_folder else "")
        status.update({"authorized": True, "defaultFolderId": folder_id})
    except SystemExit as exc:
        status.update({"authorized": False, "error": str(exc)})
        print(json.dumps(status, indent=2))
        raise
    print(json.dumps(status, indent=2))


def cmd_create_doc(args):
    creds = load_credentials()
    drive = drive_service(creds)
    docs = docs_service(creds)
    folder_id = ensure_folder_path(drive, args.folder_path)
    document = docs.documents().create(body={"title": args.title}).execute()
    doc_id = document["documentId"]
    if args.content:
        docs.documents().batchUpdate(
            documentId=doc_id,
            body={"requests": [{"insertText": {"location": {"index": 1}, "text": args.content}}]},
        ).execute()
    link = move_to_folder(drive, doc_id, folder_id)
    print(json.dumps({"documentId": doc_id, "folderId": folder_id, "title": args.title, "webViewLink": link}, indent=2))


def cmd_create_sheet(args):
    creds = load_credentials()
    drive = drive_service(creds)
    sheets = sheets_service(creds)
    folder_id = ensure_folder_path(drive, args.folder_path)
    spreadsheet = sheets.spreadsheets().create(body={"properties": {"title": args.title}}).execute()
    spreadsheet_id = spreadsheet["spreadsheetId"]
    if args.values_json:
        values = json.loads(args.values_json)
        sheets.spreadsheets().values().update(
            spreadsheetId=spreadsheet_id,
            range=args.range_name,
            valueInputOption="RAW",
            body={"values": values},
        ).execute()
    link = move_to_folder(drive, spreadsheet_id, folder_id)
    print(json.dumps({"spreadsheetId": spreadsheet_id, "folderId": folder_id, "title": args.title, "webViewLink": link}, indent=2))


def cmd_create_slides(args):
    creds = load_credentials()
    drive = drive_service(creds)
    slides = slides_service(creds)
    folder_id = ensure_folder_path(drive, args.folder_path)
    pres = slides.presentations().create(body={"title": args.title}).execute()
    presentation_id = pres["presentationId"]
    if args.text:
        page_id = pres["slides"][0]["objectId"]
        slides.presentations().batchUpdate(
            presentationId=presentation_id,
            body={
                "requests": [
                    {
                        "createShape": {
                            "objectId": "titleBox1",
                            "shapeType": "TEXT_BOX",
                            "elementProperties": {
                                "pageObjectId": page_id,
                                "size": {
                                    "height": {"magnitude": 80, "unit": "PT"},
                                    "width": {"magnitude": 480, "unit": "PT"},
                                },
                                "transform": {
                                    "scaleX": 1,
                                    "scaleY": 1,
                                    "translateX": 40,
                                    "translateY": 40,
                                    "unit": "PT",
                                },
                            },
                        }
                    },
                    {"insertText": {"objectId": "titleBox1", "text": args.text}},
                ]
            },
        ).execute()
    link = move_to_folder(drive, presentation_id, folder_id)
    print(json.dumps({"presentationId": presentation_id, "folderId": folder_id, "title": args.title, "webViewLink": link}, indent=2))


def cmd_upload_file(args):
    creds = load_credentials()
    drive = drive_service(creds)
    folder_id = ensure_folder_path(drive, args.folder_path)
    source = Path(args.file_path)
    if not source.exists():
        raise SystemExit(f"File not found: {source}")
    mime_type = args.mime_type or mimetypes.guess_type(str(source))[0] or "application/octet-stream"
    media = MediaFileUpload(str(source), mimetype=mime_type, resumable=False)
    meta = {"name": args.name or source.name, "parents": [folder_id]}
    created = drive.files().create(body=meta, media_body=media, fields="id,name,webViewLink").execute()
    print(json.dumps({"fileId": created["id"], "folderId": folder_id, "name": created["name"], "webViewLink": created.get("webViewLink")}, indent=2))


def main():
    parser = argparse.ArgumentParser(prog="gdrive-doc")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_auth = sub.add_parser("auth", help="Run local-server OAuth flow")
    p_auth.add_argument("--port", type=int, default=8091)
    p_auth.set_defaults(func=cmd_auth)

    p_status = sub.add_parser("status", help="Check readiness")
    p_status.add_argument("--resolve-default-folder", action="store_true")
    p_status.set_defaults(func=cmd_status)

    p_ensure = sub.add_parser("ensure-folder", help="Ensure Drive folder exists")
    p_ensure.add_argument("--folder-path", default=DEFAULT_FOLDER_PATH)
    p_ensure.set_defaults(func=cmd_ensure_folder)

    p_doc = sub.add_parser("create-doc", help="Create a Google Doc")
    p_doc.add_argument("--folder-path", default=DEFAULT_FOLDER_PATH)
    p_doc.add_argument("--title", required=True)
    p_doc.add_argument("--content", default="")
    p_doc.set_defaults(func=cmd_create_doc)

    p_sheet = sub.add_parser("create-sheet", help="Create a Google Sheet")
    p_sheet.add_argument("--folder-path", default=DEFAULT_FOLDER_PATH)
    p_sheet.add_argument("--title", required=True)
    p_sheet.add_argument("--range-name", default="A1")
    p_sheet.add_argument("--values-json", default="")
    p_sheet.set_defaults(func=cmd_create_sheet)

    p_slides = sub.add_parser("create-slides", help="Create a Google Slides deck")
    p_slides.add_argument("--folder-path", default=DEFAULT_FOLDER_PATH)
    p_slides.add_argument("--title", required=True)
    p_slides.add_argument("--text", default="")
    p_slides.set_defaults(func=cmd_create_slides)

    p_upload = sub.add_parser("upload-file", help="Upload a local file to Drive")
    p_upload.add_argument("--folder-path", default=DEFAULT_FOLDER_PATH)
    p_upload.add_argument("--file-path", required=True)
    p_upload.add_argument("--name", default="")
    p_upload.add_argument("--mime-type", default="")
    p_upload.set_defaults(func=cmd_upload_file)

    args = parser.parse_args()
    try:
        args.func(args)
    except Exception as exc:
        raise SystemExit(str(exc)) from exc


if __name__ == "__main__":
    main()
