# Compile check - 7 gold sample (tech_risk = memory_unsafe)

Kiem tra truoc hackathon: file nao build duoc, can gi di kem, va nen ban giao cho Bob theo don vi nao.

Da chay tren **2 moi truong**, ket luan khac nhau ro ret:

| Moi truong | Toolchain | Ket qua |
| --- | --- | --- |
| Windows 11 / MSYS2 UCRT64 | `gcc 15.2.0`, khong co libcurl | **3/7** build duoc |
| Ubuntu VM (Linux) | `gcc`, da cai `libcurl4-openssl-dev` | **7/7** build duoc |

> Ket qua Linux do nguoi dung chay va bao lai; phan Windows do phien lam viec nay tu chay.
> **Khong sua noi dung logic cua 7 file goc.** Header di kem deu copy nguyen ban tu repo mined.

## Bang tong hop (moi truong Linux - moi truong khuyen nghi)

7/7 compile OK, nhung muc do "doc lap" chia lam 3 nhom:

| Nhom | File | Compile OK | Can gi di kem | Ghi chu rui ro cho window |
| :---: | --- | :---: | --- | --- |
| **(a)** | `skpfa.c` | CO | 3 header cung thu muc goc: `commondefs.h`, `fortran_pfapack.h`, `fortran.h` | An toan nhat. Da stage + verify. |
| **(a)** | `skpf10.c` | CO | Nhu tren | An toan. Da stage + verify. |
| **(a)** | `sktrd.c` | CO | Nhu tren | An toan. Da stage + verify. |
| **(b)** | `khmm.c` | CO | `khmm.h` cung cap (da stage) | Warning `drand48` cua Windows **khong con** tren Linux - glibc co san trong `stdlib.h`. |
| **(b)** | `kopen.c` | CO (exit 0) | Khong can gi them | 1 warning: `implicit declaration of waitpid` - file goc thieu `#include <sys/wait.h>`. **Khong chan build**, chi ghi chu. Xem "Bay" ben duoi. |
| **(c)** | `clib-package.c` | CO | Header roi: `clib-cache.h`, `clib-package.h`, `asprintf/asprintf.h`, `list/list.h` **va** `-Iclib/src -Iclib/src/common -Iclib/deps` | **Gan chat vao cau truc thu muc goc.** Khong phai "doc lap that". |
| **(c)** | `clib-configure.c` | CO | Nhu tren, cung bo `-I` | Nhu tren. |

**Tom tat: 3 doc lap hoan toan - 2 doc lap voi 1 header cung cap - 2 phu thuoc cau truc thu muc.**

## Chi tiet tung nhom

### (a) Doc lap hoan toan: skpfa.c, skpf10.c, sktrd.c

Ca 3 compile `exit=0` tren ca Windows lan Linux.

Luu y quan trong da phat hien o vong kiem tra Windows: ca 3 compile duoc **tai vi tri goc**
la nho `commondefs.h` nam san canh chung. Copy rieng file `.c` ra thu muc khac la fail ngay:

```
demo/samples/before/skpfa/skpfa.c:73:10: fatal error: commondefs.h: No such file or directory
```

Chuoi phu thuoc: `skpfa.c` -> `commondefs.h` -> `fortran_pfapack.h` -> `fortran.h`.
Ca 3 header deu nam cung thu muc trong repo mined va **da duoc copy vao tung thu muc staged**,
nen sau khi stage thi 3 file nay thuc su tu chua - build duoc o bat ky dau.

> Bai hoc: dung tin ket qua compile "tai cho". Phai test tu thu muc tach roi moi biet that su
> can gi - day chinh la tinh huong Bob se gap.

### (b) Doc lap voi 1 header cung cap: khmm.c, kopen.c

`khmm.c` - tren Linux compile sach, chi can `khmm.h` dat cung cap (`khmm.h` chi include
`<stdlib.h>`, khong keo theo chuoi nao khac). Da stage.

Loi `implicit declaration of function 'drand48'` tung chan build tren Windows **khong con xuat hien
tren Linux**: `drand48` la POSIX, glibc cung cap san trong `stdlib.h`, con UCRT thi khong he co.
Day thuan tuy la khac biet nen tang, khong phai van de cua ma nguon.

`kopen.c` - tren Linux compile `exit 0`, khong can header di kem. Con **1 warning**:

```
implicit declaration of waitpid
```

File goc thieu `#include <sys/wait.h>`. Khong chan build nen khong xu ly; ghi chu lai de ban
quyet dinh. Neu muon sach warning thi them include o **file phu tro rieng**, khong sua file chinh.

#### Bay can canh giac o kopen.c

Tren Windows file nay khong build duoc, va ly do la mot **bug co san trong chinh file goc**:

```c
#ifdef _WIN32
#define _KO_NO_NET        // dong 16-18
#endif

#ifndef _KO_NO_NET        // dong 20
static int http_open(...) // dong 56  <- bi loai bo khi build tren Windows
static int ftp_open(...)  // dong 149 <- bi loai bo khi build tren Windows
#endif                    // dong 200

// nhung dong 243/247 van goi thang, KHONG he co guard:
aux->fd = http_open(fn);
aux->fd = ftp_open(fn);
```

Tac gia them nhanh `_WIN32` de tat networking nhung quen guard cho cho goi ham. Tren Linux
(`_WIN32` khong dinh nghia) thi bug nay khong lo ra - nen **build sach tren Linux khong co nghia
la code sach**. Neu Bob "sua" bang cach guard lai loi goi thi hanh vi runtime doi, khong con la
modernize thuan tuy - phai review ky diff cho nay.

### (c) Can nguyen cau truc thu muc clib/: clib-package.c, clib-configure.c

Hai file nay compile OK tren Linux **nhung khong theo kieu 1-file doc lap**. Chung can:

- Header roi: `clib-cache.h`, `clib-package.h`, `asprintf/asprintf.h`, `list/list.h`
- Va bat buoc co `-I` tro dung cho include long nhau:

```bash
cd chronos-legacy-dataset/c_financial_math/clib
gcc -c src/common/clib-package.c -Isrc -Isrc/common -Ideps -o /tmp/clib-package.o
gcc -c src/clib-configure.c      -Isrc -Isrc/common -Ideps -o /tmp/clib-configure.o
```

Doi chieu tung `#include` cua ca 2 file voi `deps/`, `src/`, `src/common/` va header he thong:
moi header deu resolve duoc tu chinh repo mined, **ngoai tru** `curl/curl.h` - day la ly do
chung fail tren Windows. Sau khi cai `libcurl4-openssl-dev` tren Linux thi het chan.

Diem mau chot: header ma 2 file nay include lai **tiep tuc include nguoc vao nhau** trong cay
`clib/`. Tach file roi ra thu muc phang se dut chuoi do, va so luong `-I` phai doan lai la khong
nho. Day la khac biet ban chat so voi nhom (a)/(b).

## Khuyen nghi ban giao cho Bob trong window

| Nhom | Don vi ban giao | Ly do |
| :---: | --- | --- |
| (a) | Thu muc rieng tung file, kem 3 header - **da stage san** | Tu chua, Bob khong phai doan gi |
| (b) | File `.c` + `khmm.h` - **da stage san** | Tu chua |
| (c) | **Dua NGUYEN thu muc `clib/`**, khong tach file roi | Include long nhau nhieu tang; tach roi thi Bob phai tu doan lai include path, rat de sai hoac bo cuoc |

Voi nhom (c), kem theo lenh build o tren de Bob khong phai suy luan lai bo `-I`.

## Trang thai thu muc staged hien tai

```
demo/samples/before/
├── clib-configure.c              <- nhom (c): staging CHUA DU, xem canh bao ben duoi
├── clib-package.c                <- nhom (c): staging CHUA DU
├── clib-cache.h, clib-package.h  <- header clib le te
├── asprintf/asprintf.h
├── list/list.h
├── common/{clib-cache.h, clib-package.h}
├── khmm.c + khmm.h               <- nhom (b): du de build
├── kopen.c                       <- nhom (b): du de build
├── skpf10/   {skpf10.c, commondefs.h, fortran_pfapack.h, fortran.h}
├── skpfa/    {skpfa.c,  commondefs.h, fortran_pfapack.h, fortran.h}
└── sktrd/    {sktrd.c,  commondefs.h, fortran_pfapack.h, fortran.h}
```

**5/7 file build duoc ngay** o cay nay: nhom (a) va nhom (b).

### Canh bao ve nhom (c)

Trong thu muc staged hien co mot phan header cua `clib` (`clib-cache.h`, `clib-package.h`,
`asprintf/`, `list/`, `common/`), nhung **bo nay chua du de build**. Doi chieu tung include:

- `clib-package.c` - con thieu **13** header: `clib-settings.h`, `debug/debug.h`, `fs/fs.h`,
  `hash/hash.h`, `http-get/http-get.h`, `logger/logger.h`, `mkdirp/mkdirp.h`,
  `parse-repo/parse-repo.h`, `parson/parson.h`, `path-join/path-join.h`, `rimraf/rimraf.h`,
  `strdup/strdup.h`, `substr/substr.h`, `tempdir/tempdir.h`
- `clib-configure.c` - con thieu `common/clib-settings.h` va `version.h`, chua ke cac include
  dang `<...>` (`commander/`, `str-flatten/`, `trim/`, ...) von phai dua vao `-Ideps`

> Luu y doc dung: "thieu" o day nghia la thieu **trong cay staged phang**, khong phai thieu khoi
> dataset. Ca `version.h` lan `clib-settings.h` deu co san trong repo mined - xem muc ngay duoi.

Day chinh la minh chung cho khuyen nghi o tren: copy le te tung header se khong bao gio duoi kip
chuoi include long nhau cua `clib/`. **Dung tiep tuc bo sung header roi** - khi vao window hay tro
Bob thang vao `chronos-legacy-dataset/c_financial_math/clib/` kem bo `-I`.

### `version.h` va `clib-settings.h` la loai gi? -> **File nguon tinh, CO SAN trong dataset**

Da kiem tra rieng 2 header nay vi chung de bi nham la do build system sinh ra.
Ket luan: **khong phai build-generated, va cung khong he thieu khoi dataset mined** -
chung chi thieu trong ban copy phang o `demo/samples/before/`.

Bang chung:

1. **Khong co build system nao trong cay mined.** `find` voi `Makefile*`, `*.mk`, `configure*`,
   `*.sh`, `*.cmake`, `CMakeLists.txt` tren `clib/` (ke ca `deps/`) tra ve **rong**. Cay mined
   chi co `src/`, `deps/`, `test/`. Nen khong ton tai rule nao de sinh ra chung.
2. **Grep khong tim thay bat ky lenh sinh file nao.** Moi tham chieu toi 2 file nay trong toan bo
   `clib/` deu chi la `#include` binh thuong trong cac file `.c` (16 cho, vi du `clib.c:21`,
   `clib-configure.c:32,45`). Khong co `echo`/`sed`/`cat` ghi ra chung, khong co rule
   `version.h: ...`.
3. **Ca hai file ton tai that, la ma nguon viet tay:**

```
chronos-legacy-dataset/c_financial_math/clib/src/version.h
chronos-legacy-dataset/c_financial_math/clib/src/common/clib-settings.h
```

`version.h` co header ban quyen viet tay va so version **hard-code**, khong phai placeholder do
script thay the:

```c
// Copyright (c) 2012-2014 clib authors / MIT licensed
#ifndef CLIB_VERSION
#define CLIB_VERSION "2.8.7"
#endif
```

`clib-settings.h` cung la hang so viet tay (`CLIB_PACKAGE_CACHE_TIME`, `MAX_THREADS`) kem mot
khai bao `extern const char *manifest_names[];`.

**He qua cho window (khong doi ket luan chinh, chi cung co them):**

- `clib-settings.h` khai bao `extern const char *manifest_names[]` nhung dinh nghia that nam o
  `src/common/clib-settings.c`. Nghia la ke ca khi compile qua duoc, buoc **link** van keo theo
  file `.c` khac -> them mot ly do nua de dua nguyen cum thu muc thay vi file roi.
- `clib-settings.h` co nhanh `#ifdef HAVE_PTHREADS`. Macro nay von do build system goc dinh nghia,
  ma build system lai **khong duoc mine ve**. Vi vay khi build thu cong, nhanh `MAX_THREADS` se bi
  loai bo am tham. Neu Bob build voi `-DHAVE_PTHREADS` con ta thi khong (hoac nguoc lai), hai ben
  se compile ra hai tap ma khac nhau - can thong nhat co build truoc khi do before/after.

## Anh huong len baseline do luong

Cac header di kem (`commondefs.h`, `fortran*.h`, `khmm.h`) **khong phai muc tieu modernize**,
neu dem vao se lam phinh baseline. Vi vay `measure.py` co co `--sources-only` (chi quet
`.c/.cpp/.cc/.cxx`) va `demo/before.json` luon duoc tao bang co nay.

**Kiem chung sau khi cap nhat moi truong build (2026-09-23):** chay lai
`measure.py --sources-only` tren toan bo `demo/samples/before/`, doi chieu voi `before.json` cu:

| Metric | Ky vong | Do duoc |
| --- | ---: | ---: |
| LOC | 3299 | 3299 |
| Cyclomatic | 788 | 788 |
| Raw pointer | 1229 | 1229 |
| Alloc | 79 | 79 |
| Free | 171 | 171 |
| Risk score (mean) | 26.53 | 26.53 |

Khop tuyet doi. So sanh o muc field: khoi `files`, `totals`, `problems`, `risk_weights` deu
**giong het nhau bit-for-bit**; khoa top-level duy nhat khac la `generated_at`. Viec them
`khmm.h` vao cay staged cung khong lam doi so lieu - dung nhu mong doi, vi `--sources-only`
loai header khoi phep do.

Dieu nay la dung ve ban chat: `measure.py` do bang tree-sitter tren van ban nguon, khong he
compile, nen ket qua doc lap voi compiler/OS. Doi moi truong build khong duoc phep lam doi
baseline - va thuc te khong doi.
