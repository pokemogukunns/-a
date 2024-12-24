from flask import Flask, render_template_string, request
import subprocess
import re

app = Flask(__name__)

@app.route('/watch')
def watch_video():
    videoid = request.args.get('v')
    if not videoid:
        return "No video ID provided", 400

    # inv.nadeko.netのURLを構築
    api_url = f"https://inv.nadeko.net/watch?v={videoid}"

    # curlコマンドでAPIから動画情報を取得
    curl_command = f"curl -s {api_url}"
    try:
        # subprocessでcurlコマンドを実行し、HTMLデータを取得
        html_content = subprocess.check_output(curl_command, shell=True, text=True)

        # メタデータを正規表現で抽出
        meta_data = {}
        meta_data["videotitle"] = re.search(r'<meta property="og:title" content="([^"]+)">', html_content)
        meta_data["videoDescription"] = re.search(r'<meta property="og:description" content="([^"]+)">', html_content)
        meta_data["videoUrl"] = re.search(r'<meta property="og:url" content="([^"]+)">', html_content)
        meta_data["videoThumbnail"] = re.search(r'<meta property="og:image" content="([^"]+)">', html_content)

        # 結果を取得し、メタデータを辞書に格納
        meta_data["videotitle"] = meta_data["videotitle"].group(1) if meta_data["videotitle"] else "Unknown Title"
        meta_data["videoDescription"] = meta_data["videoDescription"].group(1) if meta_data["videoDescription"] else "No description"
        meta_data["videoUrl"] = meta_data["videoUrl"].group(1) if meta_data["videoUrl"] else f"https://inv.nadeko.net/watch?v={videoid}"
        meta_data["videoThumbnail"] = meta_data["videoThumbnail"].group(1) if meta_data["videoThumbnail"] else "https://img.youtube.com/vi/{videoid}/0.jpg"

        # テンプレートに渡すデータ
        video_data = {
            "videotitle": meta_data["videotitle"],
            "videoDescription": meta_data["videoDescription"],
            "videoUrl": meta_data["videoUrl"],
            "videoThumbnail": meta_data["videoThumbnail"],
            "videoId": videoid
        }

        html_template = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>{{ videotitle }}</title>
            <link rel="stylesheet" href="https://pokemogukunns.github.io/yuki-math/css/empty.css">
            <script src="https://code.jquery.com/jquery-3.5.1.js"></script>
        </head>
        <body>
            <h1>{{ videotitle }}</h1>
            <video width="100%" controls poster="{{ videoThumbnail }}">
                <source src="{{ videoUrl }}">
            </video>
            <p><strong>Video Description:</strong> {{ videoDescription }}</p>
            <p><strong>Video URL:</strong> <a href="{{ videoUrl }}">{{ videoUrl }}</a></p>
        </body>
        </html>
        """
        # レンダリングして返す
        return render_template_string(html_template, **video_data)

    except subprocess.CalledProcessError:
        return "Failed to retrieve video information", 500


if __name__ == '__main__':
    app.run(debug=True)
