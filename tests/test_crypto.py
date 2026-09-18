import pytest
from analyzer.crypto import analyze_crypto


def test_crypto_detection():
    code = """
    SHA1_Init(&ctx);
    SHA1_Update(&ctx, data, len);
    SHA1_Final(hash, &ctx);

    MD5_Init(&md5_ctx);
    RSA_generate_key(1024, 65537, NULL, NULL);
    """
    res = analyze_crypto(code)

    assert res["has_sha1"] == 1
    assert res["sha1_count"] >= 3
    assert res["has_md5"] == 1
    assert res["has_legacy_rsa"] == 1
    assert res["legacy_crypto_count"] >= 5
    assert "SHA1" in res["crypto_algorithms_detected"]
    assert "MD5" in res["crypto_algorithms_detected"]
    assert "RSA" in res["crypto_algorithms_detected"]
