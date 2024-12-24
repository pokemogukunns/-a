import subprocess
from bs4 import BeautifulSoup
from flask import Flask, request, jsonify

app = Flask(__name__)

def fetch_html(url):
    """指定されたURLのHTMLをcurlコマンドで取得する"""
    try:
        result = subprocess.run(['curl', '-s', url], capture_output=True, text=True)
        return result.stdout
    except Exception as e:
        print(f"Error: {e}")
        return None

def extract_video_url(html):
    """HTMLからmetaタグを探してvideolinkを取得する"""
    soup = BeautifulSoup(html, 'html.parser')
    
    # og:video:secure_url メタタグを取得
    meta_tag = soup.find('meta', {'property': 'og:video:secure_url'})
    
    if meta_tag and meta_tag.get('content'):
        videolink = meta_tag['content']
        return videolink
    return None

@app.route('/')
def home():
    """ホームページのHTMLを取得して表示"""
    url = "https://inv.nadeko.net/"
    html = fetch_html(url)
    
    if not html:
        return "Error fetching home page", 400
    
    return html  # ホームページのHTMLをそのまま返す

@app.route('/watch')
def watch():
    """動画情報を取得してvideolinkを代入"""
    videoid = request.args.get('v')  # ?v=videoidの形式でvideoidを取得
    if not videoid:
        return "Error: videoid not provided", 400

    url = f"https://inv.nadeko.net/watch?v={videoid}"
    html = fetch_html(url)
    
    if not html:
        return f"Error  うまく取得できませんでした再読み込みを試してください {videoid}", 400

    videolink = extract_video_url(html)
    
    if videolink:
        video_tag = f'<video controls><source src="{videolink}" type="video/mp4"></video>'
        return video_tag
    else:
        return f"Error: videolink not found for video with id {videoid}", 400

@app.route('/channel')
def channel():
    """チャンネル情報を取得"""
    channelid = request.args.get('c')  # ?c=channelidの形式でchannelidを取得
    if not channelid:
        return "Error: channelid not provided", 400

    url = f"https://inv.nadeko.net/channel?c={channelid}"
    html = fetch_html(url)
    
    if not html:
        return f"Error fetching channel with id {channelid}", 400

    return html  # チャンネルのHTMLをそのまま返す

@app.route('/playlist')
def playlist():
    """プレイリスト情報を取得"""
    playlistid = request.args.get('p')  # ?p=playlistidの形式でplaylistidを取得
    if not playlistid:
        return "Error: playlistid not provided", 400

    url = f"https://inv.nadeko.net/playlist?p={playlistid}"
    html = fetch_html(url)
    
    if not html:
        return f"Error fetching playlist with id {playlistid}", 400

    return html  # プレイリストのHTMLをそのまま返す

@app.route('/search')
def search():
    """検索結果を取得"""
    searchword = request.args.get('q')  # ?q=searchwordの形式でsearchwordを取得
    if not searchword:
        return "Error: searchword not provided", 400

    url = f"https://inv.nadeko.net/search?q={searchword}"
    html = fetch_html(url)
    
    if not html:
        return f"Error fetching search results for {searchword}", 400

    return html  # 検索結果のHTMLをそのまま返す

if __name__ == '__main__':
    app.run(debug=True)
