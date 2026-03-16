+++
title = "History of Machine Learning Potential (draft)"
tags = ["simulation", "force field", "machine learning potential"]
summary = ""
+++

# "History of Machine Learning Potential (draft)"

逐次更新します．

# 2023 
- Chmiela, S.; Vassilev-Galindo, V.; Unke, O. T.; Kabylda, A.; Sauceda, H. E.; Tkatchenko, A.; Müller, K.-R. Accurate Global Machine Learning Force Fields for Molecules with Hundreds of Atoms. _Sci. Adv._ **2023**, _9_ (2), eadf0873. https://doi.org/10.1126/sciadv.adf0873.
  - 大きい分子に対して，局所相互作用のみの仮定を課しているので，非局所的な相互作用が既存のMLFFでは記述できていない問題があった．
  - Global symmetric gradient domain machine learning (sGDML) force fieldsを開発．~100 atoms系が対象．
  - もう一つの貢献として，PBE0+MBD levelの第一原理計算を中分子程度の大きさに適用し，動力学のデータセットを作った．MD22(42 ~ 370 atoms)と言われるベンチマーク． ns path-integral MD simulationsを実行して得たものっぽい？
- Wang, T.; He, X.; Li, M.; Shao, B.; Liu, T.-Y. AIMD-Chig: Exploring the Conformational Space of a 166-Atom Protein Chignolin with Ab Initio Molecular Dynamics. _Sci. Data_ **2023**, _10_ (1), 549. https://doi.org/10.1038/s41597-023-02465-9.
  - chignolinに対するab initio MDのデータ論文
  - datasetのリンク
    - https://doi.org/10.6084/m9.figshare.22786730

# 2024
- Wang, T.; He, X.; Li, M.; Li, Y.; Bi, R.; Wang, Y.; Cheng, C.; Shen, X.; Meng, J.; Zhang, H.; Liu, H.; Wang, Z.; Li, S.; Shao, B.; Liu, T.-Y. Ab Initio Characterization of Protein Molecular Dynamics with AI2BMD. _Nature_ **2024**, _635_ (8040), 1019–1027. https://doi.org/10.1038/s41586-024-08127-z.
  - 
- Frank, J. T.; Unke, O. T.; Müller, K.-R.; Chmiela, S. A Euclidean Transformer for Fast and Stable Machine Learned Force Fields. _Nat. Commun._ **2024**, _15_ (1), 6539. https://doi.org/10.1038/s41467-024-50620-6.
  - Transformerベースのモデル(SO3krates)でMLFFを構築した論文．
- Unke, O. T.; Stöhr, M.; Ganscha, S.; Unterthiner, T.; Maennel, H.; Kashubin, S.; Ahlin, D.; Gastegger, M.; Medrano Sandonas, L.; Berryman, J. T.; Tkatchenko, A.; Müller, K.-R. Biomolecular Dynamics with Machine-Learned Quantum-Mechanical Force Fields Trained on Diverse Chemical Fragments. _Sci. Adv._ **2024**, _10_ (14), eadn4397. https://doi.org/10.1126/sciadv.adn4397.
  - 小分子と大きい分子のデータをQM計算で取得し，bottom upとtop downによる学習をしたMLFF．(deepmind)
  - GEMSのこと．

# 2025
- Kabylda, A.; Frank, J. T.; Suárez-Dou, S.; Khabibrakhmanov, A.; Medrano Sandonas, L.; Unke, O. T.; Chmiela, S.; Müller, K.-R.; Tkatchenko, A. Molecular Simulations with a Pretrained Neural Network and Universal Pairwise Force Fields. _J. Am. Chem. Soc._ **2025**, _147_ (37), 33723–33734. https://doi.org/10.1021/jacs.5c09558.
  - PBE0+MBD levelのQMの動力学データを学習したSO3kratesを取得．
  - SO3kratesはsemilocalな相互作用(近距離の多体相互作用や結合，角度，2面角など)のエネルギー，Hirsheld ratio，電荷を返す．
  - long-rangeはvdWとCoulomb potentialで記述．電荷やvdWのパラメタはSO3kratesで予測する．
  - pipで入れれて，colab notebookでも試せて使いやすい．
  - waterもproteinもglycoproteinもlipidもbaseも計算が走る．すごいな．
    - 古典力場で苦しんでいたトポロジーファイルの作成がいらないのでとっても楽ちん．というか，これがAb initio MDの楽さか．必要な準備をすべて重たい計算に押し付けている感じ．ユーザとしては気軽に計算ができるので良いよね．
  - Journal clubで発表したのでスライド参照．．．．
