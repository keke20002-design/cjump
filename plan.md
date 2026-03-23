빌드버젼 자동추가 로직 

def getTimestamp() {
    return new Date().format('yyMMddHHmm').toInteger()
}

android {
    defaultConfig {
        // versionCode는 정수(Integer)여야 하므로 타임스탬프 활용
        versionCode getTimestamp()
        
        // versionName은 보기 편하게 날짜 형식으로 자동 생성
        versionName "1.0." + new Date().format('yyyyMMdd')
        
        // ... 생략
    }
}