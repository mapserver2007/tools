# ミリオンで機械学習

## やりたいこと
* あつめたミリ画像を自動分類
* 好みの画像だけ集めたい

## 環境構築
### Windows
* Python3
    * https://www.python.org/downloads/windows/
* Jupyter notebook
    * Anacondaを入れると自動的に入るのでそれを利用する
* Tensorflow
    * pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org tensorflow==1.15.0
        * https://q.hatena.ne.jp/1558242750
        * ファイルパスの長さをレジストリ変更で無制限に変えておかないとエラーになる
* Keras
    * pip install --upgrade pip
    * pip install --upgrade setuptools