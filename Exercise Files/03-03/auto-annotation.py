import os

# Auto annotation
from ultralytics.data.annotator \
    import auto_annotate

# auto_annotate(data="dataset/test/images",
#               det_model="best.pt",
#               sam_model="sam_b.pt")
# auto_annotate(data="dataset/train/images",
#               det_model="best.pt",
#               sam_model="sam_b.pt")
# auto_annotate(data="dataset/val/images",
#               det_model="best.pt",
#               sam_model="sam_b.pt")
#

# Replace the labels_folder names
[os.rename(os.path.join(dp, d),
           os.path.join(dp,
                        "labels"))
 for dp, dn, _ in os.walk("dataset")
 for d in dn if d == "images_auto_annotate_labels"]
