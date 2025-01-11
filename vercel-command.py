import subprocess
import sys
#ここから
import os

# ファイルで初回実行チェック
if not os.path.exists("executed_once.txt"):
    print("Running vercel-command.py for the first time!")
    # 必要な処理をここに書く
    with open("executed_once.txt", "w") as f:
        f.write("done")
else:
    print("Skipping vercel-command.py, already executed.")


#ここまで



def run_command(command):
    """コマンドを実行し、結果を表示"""
    try:
        result = subprocess.run(command, shell=True, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(result.stdout)  # 標準出力の内容を表示
        print(result.stderr)  # 標準エラーの内容を表示
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        print(e.stderr)
        sys.exit(1)


def check_and_install_crystal():
    """Crystalがインストールされていない場合はインストール"""
    try:
        subprocess.run("crystal --version", shell=True, check=True)
        print("Crystal is already installed.")
    except subprocess.CalledProcessError:
        print("Crystal is not installed. Installing Crystal...")
        run_command("sudo apt update")
        run_command("sudo apt install -y crystal")


def check_and_install_shards():
    """Shardsがインストールされていない場合はインストール"""
    try:
        subprocess.run("shards --version", shell=True, check=True)
        print("Shards is already installed.")
    except subprocess.CalledProcessError:
        print("Shards is not installed. Installing Shards...")
        run_command("sudo apt install -y crystal-shards")


def get_flags():
    """Makefileのフラグ設定を再現"""
    flags = []
    
    # フラグの設定
    RELEASE = 1
    STATIC = 0
    MT = 0
    NO_DBG_SYMBOLS = 0
    API_ONLY = 0

    if RELEASE == 1:
        flags.append("--release")
    if STATIC == 1:
        flags.append("--static")
    if MT == 1:
        flags.append("-Dpreview_mt")
    if NO_DBG_SYMBOLS == 1:
        flags.append("--no-debug")
    else:
        flags.append("--debug")
    if API_ONLY == 1:
        flags.append("-Dapi_only")

    return " ".join(flags)


def get_libs():
    """shards install --production を実行"""
    print("Running: shards install --production")
    run_command("shards install --production")


def build_invidious(flags):
    """Invidiousをビルドする"""
    print(f"Running: crystal build invidious/src/invidious.cr {flags} --progress --stats --error-trace")
    run_command(f"crystal build invidious/src/invidious.cr {flags} --progress --stats --error-trace")


def run_invidious():
    """Invidiousを実行する"""
    print("Running: ./invidious")
    run_command("./invidious")


def format_code():
    """コードをフォーマットする"""
    print("Running: crystal tool format")
    run_command("crystal tool format")


def run_tests():
    """テストを実行する"""
    print("Running: crystal spec")
    run_command("crystal spec")


def verify_code(flags):
    """コードを検証する（ビルドせず）"""
    print(f"Running: crystal build invidious/src/invidious.cr -Dskip_videojs_download --no-codegen {flags} --progress --stats --error-trace")
    run_command(f"crystal build invidious/src/invidious.cr -Dskip_videojs_download --no-codegen {flags} --progress --stats --error-trace")


def clean():
    """ビルド成果物を削除する"""
    print("Running: rm invidious")
    run_command("rm invidious")


def distclean():
    """ビルド成果物とライブラリを削除する"""
    clean()
    print("Running: rm -rf libs")
    run_command("rm -rf libs")
    print("Running: rm -rf ~/.cache/{crystal,shards}")
    run_command("rm -rf ~/.cache/{crystal,shards}")


def print_help():
    """ヘルプページを表示"""
    print("""
    Targets available:
    get-libs         Fetch Crystal libraries
    invidious        Build Invidious
    run              Launch Invidious
    format           Run the Crystal formatter
    test             Run tests
    verify           Just make sure that the code compiles, but without generating any binaries.
    clean            Remove build artifacts
    distclean        Remove build artifacts and libraries
    help             Show this help message
    """)


def main():
    # Crystal と Shards がインストールされていない場合、インストール
    check_and_install_crystal()
    check_and_install_shards()

    flags = get_flags()

    # コマンド実行の順番を固定
    get_libs()             # ライブラリのインストール
    build_invidious(flags) # Invidiousのビルド
    run_invidious()        # Invidiousを実行


if __name__ == "__main__":
    main()
