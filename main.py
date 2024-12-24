from flask import Flask, render_template, request
import subprocess
import socket

app = Flask(__name__)

@app.route('/', methods=['GET', 'POST'])
def index():
    result = None
    if request.method == 'POST':
        url = request.form['url']
        try:
            # curlコマンドを実行
            result = subprocess.check_output(['curl', url], stderr=subprocess.STDOUT, universal_newlines=True)
        except subprocess.CalledProcessError as e:
            result = f"Error: {e.output}"

    return render_template('index.html', result=result)

if __name__ == '__main__':
    temp_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    temp_socket.bind(("0.0.0.0", 0))  # ポート番号に0を指定して空いているポートを選択
    port = temp_socket.getsockname()[1]  # 割り当てられたポートを取得
    temp_socket.close()  # 一時的なソケットは閉じる

    print(f"Flask server will run on port {port}")
    app.run(host="0.0.0.0", port=port)
