# multi-segment executable file template.

data segment
    # add your data here!
    pkey db "press any key...$"
    PRN dw 0 # save the last random number
    map db 100 dup(0)
    headX dw 3
    headY dw 2
    tailX dw 1
    tailY dw 2
    fruitX dw 0
    fruitY dw 0
    lastPress db 2
ends

stack segment
    dw   128  dup(0)
ends

code segment
    assume ds:data
start:        
    mov ax, data
    mov ds, ax
    call initialMap   
    call initialSnake
    call initialFruit
LOOP:
    call printMap
    call unBlockedInput
    cmp ax, 0
    je LOOP2
    mov lastPress, al # have been a bug
    call changeHeadDirection # change di
LOOP2:
    call calHeadIndex
    call changeHeadPos # change cx
    call changeTailPos
    #call checkOver
    #call checkEatFruit
    call clearScrean
    jmp LOOP

    mov ah, 4ch
    int 21h
initialMap:
    # preCond : none
    # postCond : initial the map
    push di
    mov di, 0
HeadBar:
    cmp di, 10
    jge BottomBar
    mov [map + di], 9 # 9 means wall
    inc di
    jmp HeadBar
BottomBar:
    mov di, 90
BottomBarLoop:
    cmp di, 100
    jge LeftBar
    mov [map + di], 9    
    inc di
    jmp BottomBarLoop
LeftBar:
    mov di, 0
LeftBarLoop:
    cmp di, 90
    jg RightBar
    mov [map + di], 9
    add di, 10
    jmp LeftBarLoop
RightBar:
    mov di, 9
RightBarLoop:
    cmp di, 99
    jge initialMapEnd
    mov [map + di], 9
    add di, 10
    jmp RightBarLoop
initialMapEnd:
    pop di
    ret

initialSnake:
    mov [map + 21], 2
    mov [map + 22], 2
    mov [map + 23], 2
    ret

printMap:
    mov di, 0
    mov cx, 10
printMapLoop:
    cmp di, 100
    jge printMapEnd
    # \n\r
    mov ax, di
    div cl
    cmp ah, 0
    je printEnter
printOthers:
    call calHeadIndex
    cmp di, ax
    je printHead
    cmp [map + di], 9
    je printWall
    cmp [map + di], 0
    je printSpace
    cmp [map + di], 8
    je printFruit
    jmp printBody
printWall:
    mov dl, '*'
    call printASCII
    inc di
    jmp printMapLoop
printSpace:
    mov dl, ' '
    call printASCII
    inc di
    jmp printMapLoop
printEnter:
    mov dl, 0DH
    call printASCII  
    mov dl, 0AH
    call printASCII
    jmp printOthers
printHead:
    mov dl, '@'
    call printASCII
    inc di
    jmp printMapLoop
printBody:
    mov dl, '&'
    call printASCII
    inc di
    jmp printMapLoop
printFruit:
    mov dl, '!'
    call printASCII
    inc di
    jmp printMapLoop
printMapEnd:
    ret

initialFruit:
    #preCond : none
    # postCond : change fruitX and fruitY to an empty space
    push di
    call getRandom
    mov fruitX, ax
    call getRandom
    mov fruitY, ax
    mov bx, fruitX
    mov cx, fruitY
    call getIndex
    mov di, ax
    cmp [map + di], 0
    je initialFruitEND
    pop di
    jmp initialFruit
initialFruitEND:
    mov [map + di], 8
    pop di
    ret

changeHeadPos:
    # preCond : ax is head index
    # postCond: adjust headX and headY
    # change: cx
    push di
    mov di, ax
    mov cl, [map + di]
    cmp [map + di], 1
    je headUp
    cmp [map + di], 2
    je headRight
    cmp [map + di], 3
    je headDown
    cmp [map + di], 4
    je headLeft
changeHeadPosFinish:
    call calHeadIndex
    mov di, ax
    mov [map + di], cl
    pop di
    ret
headUp:
    mov ax, headY
    dec ax
    mov headY, ax
    jmp changeHeadPosFinish
headDown:
    mov ax, headY
    inc ax
    mov headY, ax
    jmp changeHeadPosFinish
headLeft:
    mov ax, headX
    dec ax
    mov headX, ax
    jmp changeHeadPosFinish
headRight:
    mov ax, headX
    inc ax
    mov headX, ax
    jmp changeHeadPosFinish

changeTailPos:
    push di
    push bx
    call calTailIndex
    mov di, ax
    mov bl, [map + di]
    cmp bx, 1
    je changeTailPosUp
    cmp bx, 2
    je changeTailPosRight
    cmp bx, 3
    je changeTailPosDown
    cmp bx, 4
    je changeTailPosLeft
changeTailPosFinish:
    mov [map + di], 0
    pop bx
    pop di
    ret
changeTailPosUp:
    mov ax, tailY
    dec ax
    mov tailY, ax
    jmp changeTailPosFinish
changeTailPosRight:
    mov ax, tailX
    inc ax
    mov tailX, ax
    jmp changeTailPosFinish
changeTailPosDown:
    mov ax, tailY
    inc ax
    mov tailY, ax
    jmp changeTailPosFinish
changeTailPosLeft:
    mov ax, tailX
    dec ax
    mov tailX, ax
    jmp changeTailPosFinish


changeHeadDirection:
    # preCond : ax must be the key it pressed
    # postCond : change direction
    # change : di
    push bx
    push cx
    call calHeadIndex
    mov di, ax
    mov bl, lastPress
    mov cl, [map + di]
    cmp bl, 'w'
    je changeHeadToUp
    cmp bl, 'd'
    je changeHeadToRight
    cmp bl, 's'
    je changeHeadToDown
    cmp bl, 'a'
    je changeHeadToLeft
changeHeadDirectionFinish:
    pop cx
    pop bx
    ret
changeHeadToUp:
    mov [map + di], 1
    jmp changeHeadDirectionFinish
changeHeadToRight:
    mov [map + di], 2
    jmp changeHeadDirectionFinish
changeHeadToDown:
    mov [map + di], 3
    jmp changeHeadDirectionFinish
changeHeadToLeft:
    mov [map + di], 4
    jmp changeHeadDirectionFinish
    



unBlockedInput:
    # preCond: none
    # postCond : ax is ascii that is read or ZERO(TODO) if no key pressed
    mov al, 0
    mov ah, 1
    int 16h # test whether a key is pressed
    cmp ah, 1 
    je unBlockedInputEnd

    mov al, 0
    mov ah, 0
    int 16h 
    ret
    # now ax is what you want
unBlockedInputEnd:
    mov ax, 0
    ret 
    
printASCII:
    # preCond : dl is the ascii that should be output
    # postCond : print out the ascii in screen
    Mov ah, 02h
    Int 21h  
    ret  


getRandom:
    # preCond : dx is the last random number
    # post ax : random number 0 ~ 9
    # change ax, cx, dx
    mov AH, 00h   # interrupt to get system timer in CX:DX 
    int 1AH
    mov [PRN], dx
    call CalcNew   # -> AX is a random number
    xor dx, dx
    mov cx, 10    
    div cx        # here dx contains the remainder - from 0 to 9
    mov ax, dx
    ret
CalcNew:
    mov ax, 25173
    mul word ptr [PRN]
    add ax, 13849
    mov [PRN], ax
    ret
getIndex:
    # preCond : bx is X, cx is Y for point(x, y)
    # postCond : ax = y * 10 + x
    push cx
    mov ax, cx             
    mov cx, 10
    mul cx
    add ax, bx       
    pop cx
    ret
clearScrean:
    # preCond : none
    # postCond : clear the screen
    mov ax, 3h
    int 10h
    ret
calHeadIndex:
    # preCond : none
    # postCond : ax <- index of head
    push dx
    mov ax, headY
    mov dx, 10
    mul dx
    add ax, headX
    pop dx
    ret
calTailIndex:
    # preCond : none
    # postCond : ax <- index of head
    push dx
    mov ax, tailY
    mov dx, 10
    mul dx
    add ax, tailX
    pop dx
    ret    
code ends
end start # set entry point and stop the assembler.