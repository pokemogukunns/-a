from flask import Flask, render_template_string, request
import subprocess
from bs4 import BeautifulSoup

app = Flask(__name__)

@app.route('/watch')
def watch_video():
    videoid = request.args.get('v')
    if not videoid:
        return "No video ID provided", 400

    # inv.nadeko.netのURLを構築
    api_url = f"https://inv.nadeko.net/watch?v={videoid}"

    # curlコマンドでHTMLを取得
    curl_command = f"curl -s {api_url}"
    try:
        # subprocessでcurlコマンドを実行してHTMLを取得
        html_content = subprocess.check_output(curl_command, shell=True, text=True)

        # BeautifulSoupでHTMLをパース
        soup = BeautifulSoup(html_content, 'html.parser')

        # metaタグの情報を取得
        og_video = soup.find('meta', property='og:video')
        og_video_url = soup.find('meta', property='og:video:url')

        # 必要な情報を取り出す
        video_url = og_video['content'] if og_video else 'No video URL'
        video_url2 = og_video_url['content'] if og_video_url else 'No video URL'

        # 動画情報を取得（他にも必要な情報があれば追加）
        title = soup.find('title').text if soup.find('title') else 'Unknown'
        description = soup.find('meta', attrs={'name': 'description'})['content'] if soup.find('meta', attrs={'name': 'description'}) else 'No description'

        # HTMLテンプレートに渡すデータ
        return render_template_string(html_template, title=title, videoId=videoid, description=description, 
                                      videourl=video_url, videoUrl2=video_url2)

    except subprocess.CalledProcessError:
        return "Failed to retrieve HTML content", 500


# HTMLテンプレート
html_template = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{{ title }}</title>
    </head>
    <body>
        <h1>{{ title }}</h1>
        <p><strong>Video ID:</strong><a href="/watch?v={{ videoId }}">{{ videoId }}</a></p>
        <p><strong>Description:</strong> {{ description }}</p>
          <!--<video src="{ videoUrl }"></video>-->
        <p><strong>音声ファイル:</strong> <a href="{{ videoUrl2 }}">音声ファイル</a></p>
    <video id="videoElement" controls>
        <source id="videoSource" src="{{ videourl }}" type="video/mp4">
        お使いのブラウザはvideoタグに対応していません。
    </video>

    <script>
        // metaタグから動画URLを取得
        const videoUrl = document.querySelector('meta[property="og:video"]').getAttribute('content');

        // <video>タグに動画URLを設定
        const videoElement = document.getElementById('videoElement');
        const videoSource = document.getElementById('videoSource');
        videoSource.src = videoUrl;
        videoElement.load();  // 動画をロード
    </script>
    </body>
    </html>
    """

if __name__ == '__main__':
    app.run(debug=True)
