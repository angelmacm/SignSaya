import pandas, os
trainDir = "../../../../../../Downloads/Data Gathered (Anj)-20240504T063815Z-001/Data Gathered (Anj)"
saveModified = "../../../../../../Downloads/githubRepos/modified"
totalFailed = 0
failedList = []
folderNames = os.listdir(trainDir)
for folder in folderNames:
    foldpath = os.path.join(trainDir, folder)
    filelist = os.listdir(foldpath)
    for file in filelist:
        fpath = os.path.join(foldpath, file)
        newPath = os.path.join(str(foldpath).replace("Data Gathered (Anj)-20240504T063815Z-001/Data Gathered (Anj)", "githubRepos/modified"), file)
        print(f"Opening {file}")
        csvFile = open(fpath,'r', encoding="utf-8")
        newFile = open(newPath,"a", encoding="utf-8")
        newFile.write(csvFile.readlines()[0])
        csvFile.close()
        csvFile = open(fpath,'r', encoding="utf-8")
        for r in csvFile.readlines()[1:]:
            currentString = ""
            # print(r)
            for entries in r.split(","):
                if entries == r.split(",")[0]:
                    secondEntry = entries[-3:]
                    firstEntry = entries[:-3]
                    currentString += firstEntry +","+ secondEntry
                else:
                    currentString += ","+entries
                # print(currentString)
                    
            if(len(currentString.split(",")) ==10):
                pass
            else:
                # failedList.append({file: currentString})
                continue
            newFile.write(currentString)
            
        newFile.close()
        csvFile.close()
    # input()
    # [print(x) for x in failedList]
            # print(f"{r} == {currentString}")
        # df = pandas.read_csv(fpath)
        # print(df)