# Tripping_SNPs

Author:Defne Yanartas

Date:March 2023

Sections:
1. Installing and set-up
2. Data
3. Programs
4. Results

## 1. Installing and set-up
Worked in the penthouse computer for this section.

Install plink (version v1.07 )

```bash
wget https://zzz.bwh.harvard.edu/plink/dist/plink-1.07-x86_64.zip   #download to the bin
unzip plink-1.07-x86_64.zip                                         #after that, add the directory to the path
```

Set up the project directory(git repository)
```bash
mkdir Data
mkdir Programs

gitinit
git remote add origin git@github.com:defneyanartas/Tripping_SNPs.git
git branch -M main
git push --set-upstream origin main 


```

## 2. Data
Worked in the penthouse computer for this section.
```bash
echo "Data/" >> .gitignore                                        #I dont wan to track the Data files, the are large and we dont need them in github.
git add .gitignore
git commit -m "Add Data directory to the ignore file"             #From now on I will not type each time I commit, general procedure is that I commit with every new file/folder/update.
```



```bash
cat Eurasian.map | cut -f 2 | whiel read line; do echo $line > extract.txt; plink --bfile Eurasian --extract extract.txt --recode --out $line --noweb; done
```

## 3. Programs
Created programs in my personal laptop and moved them to penthouse computer.
```
```
## 4. Results
```
```



















