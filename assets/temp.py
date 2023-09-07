f = open('labelmap.txt', 'r')
f2 = open('temp.txt', 'w')
lines = f.readlines()
i = 0
for line in lines:
    temp = str(i) + ' ' + line.strip()
    f2.write(temp+'\n')
    i+=1
    
f.close()
f2.close()
