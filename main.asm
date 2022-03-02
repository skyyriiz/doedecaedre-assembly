; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XNextEvent

; Ajout printf
extern printf

; external functions from stdio library (ld-linux-x86-64.so.2)    
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1
%define teste 4

global main


section .bss
display_name:	resq	1
screen:		resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1

; Création variable
x1: resd 1
y1: resd 1
x2: resd 1
y2: resd 1
x3: resd 1
y3: resd 1
x21: resd 1
y21: resd 1
x31: resd 1
y31: resd 1
result_1: resd 1
result_2: resd 1

section .data

; Ajout variable
Xo: dd 400.0
Yo: dd 400.0
Zo: dd 800.0
df: dd 1600.0
cos_45: dd 0.70710678118
sin_45: dd 0.70710678118
line: dd 3

event:		times	24 dq 0

; Un point par ligne sous la forme X,Y,Z
dodec:	        dd	0.0,50.0,80.901699		; point 0
		dd 	0.0,-50.0,80.901699		; point 1
		dd 	80.901699,0.0,50.0		; point 2
		dd 	80.901699,0.0,-50.0		; point 3
		dd 	0.0,50.0,-80.901699		; point 4
		dd 	0.0,-50.0,-80.901699	        ; point 5
		dd 	-80.901699,0.0,-50.0	        ; point 6
		dd 	-80.901699,0.0,50.0		; point 7
		dd 	50.0,80.901699,0.0		; point 8
		dd 	-50.0,80.901699,0.0		; point 9
		dd 	-50.0,-80.901699,0.0	        ; point 10
		dd	50.0,-80.901699,0.0		; point 11

; Une face par ligne, chaque face est composée de 3 points tels que numérotés dans le tableau dodec ci-dessus
; Les points sont donnés dans le bon ordre pour le calcul des normales.
; Exemples :
; pour la première face (0,8,9), on fera le produit vectoriel des vecteurs 80 (vecteur des points 8 et 0) et 89 (vecteur des points 8 et 9)	
; pour la deuxième face (0,2,8), on fera le produit vectoriel des vecteurs 20 (vecteur des points 2 et 0) et 28 (vecteur des points 2 et 8)
; etc...
faces:	        dd	0,8,9,0
		dd	0,2,8,0
		dd	2,3,8,2
		dd	3,4,8,3
		dd	4,9,8,4
		dd	6,9,4,6
		dd	7,9,6,7
		dd	7,0,9,7
		dd	1,10,11,1
		dd	1,11,2,1
		dd	11,3,2,11
		dd	11,5,3,11
		dd	11,10,5,11
		dd	10,6,5,10
		dd	10,7,6,10
		dd	10,1,7,10
		dd	0,7,1,0
		dd	0,1,2,0
		dd	3,5,4,3
		dd	5,6,4,5


section .text


;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:

;####################################
;## Code de création de la fenêtre ##
;####################################
xor     rdi,rdi
call    XOpenDisplay	; Création de display
mov     qword[display_name],rax	; rax=nom du display

mov     rax,qword[display_name]
mov     eax,dword[rax+0xe0]
mov     dword[screen],eax

mov rdi,qword[display_name]
mov esi,dword[screen]
call XRootWindow
mov rbx,rax

mov rdi,qword[display_name]
mov rsi,rbx
mov rdx,10
mov rcx,10
mov r8,400	; largeur
mov r9,400	; hauteur
push 0xFFFFFF	; background  0xRRGGBB
push 0x00FF00
push 1
call XCreateSimpleWindow
mov qword[window],rax

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,131077 ;131072
call XSelectInput

mov rdi,qword[display_name]
mov rsi,qword[window]
call XMapWindow

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,0
mov rcx,0
call XCreateGC
mov qword[gc],rax

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov rdx,0x000000	; Couleur du crayon
call XSetForeground

; boucle de gestion des évènements
boucle: 
	mov rdi,qword[display_name]
	mov rsi,event
	call XNextEvent

	cmp dword[event],ConfigureNotify
	je prog_principal
	cmp dword[event],KeyPress
	je closeDisplay
jmp boucle

;##################################################
;###jump_ligne du code de création de la fenêtre###
;##################################################

;############################################
;###Ici commence VOTRE programme principal###
;############################################ 

; Les formules finales de projection d'un point 3D (X,Y,Z) en point 2D (X',Y') sont :
; X' = (df * X) / (Z + Zo) + Xo
; Y' = (df * Y) / (Z + Zo) + Yo
; df fait varier la longueur des points
; Zo fait varier le zoom sur l'objet
; Yo fait varier la position de l'objet en Y
; Xo fait varier la position de l'objet en X

; On calcule les coordonnées de deux vecteurs :
; Les points sont calculés après la projection en 2D
; X21 = X2 - X1
; Y21 = Y2 - Y1
; X31 = X3 - X1
; Y31 = Y3 - Y1
; On calcule la normale :
; (X21 * Y31) - (X31 * Y21)
; Si le résultat est supérieur à 0 on fait tracer la ligne

; Selon l'axe Z, les transformations seront :
; Les points sont calculés avant la projection en 2D
; X = X * cos(angZ) - Y * sin(angZ)
; Y = X * sin(angZ) + Y * cos(angZ)
; Z = Z

prog_principal:
push rbp

mov r13d, 0 ;Va parcourir les valeurs du tableau de faces


big_loop:


mov r10d, dword[line] ; Utiliser pour trouver X
imul r10d, dword[faces + r13d * DWORD] ; Pour se placer sur X

movss xmm0, [cos_45]
mulss xmm0, dword[dodec + r10d * DWORD] ; X * cos(45)
inc r10d ; Pour se placer sur Y
movss xmm15, [sin_45]
mulss xmm15, dword[dodec + r10d * DWORD] ; Y * sin(45)
subss xmm0, xmm15 ; X = X * cos(45) - Y * sin(45)

mulss xmm0, [df] ; X * df
inc r10d ; Pour se placer sur Z
movss xmm15, dword[dodec + r10d * DWORD] ; On prend la valeur en coordonnée Z du point
addss xmm15, [Zo] ; Z + Zo
divss xmm0, xmm15 ; (df * X) / (Z + Zo)
addss xmm0, [Xo] ; X' = (df * X) / (Z + Zo) + Xo

cvtss2si r15d, xmm0 ; On convertie le point en entier
mov dword[x1], r15d ; pour sauvgarder la valeur en x1

dec r10d ; Pour se placer sur Y

movss xmm0, [cos_45]
mulss xmm0, dword[dodec + r10d * DWORD] ; Y * cos(45)
dec r10d ; Pour se placer sur X
movss xmm15, [sin_45]
mulss xmm15, dword[dodec + r10d * DWORD] ; X * sin(45)
addss xmm0, xmm15 ; Y = X * sin(45) + Y * cos(45) 

add r10d, 2 ; Pour se placer sur Z
mulss xmm0, [df] ; Y * df
movss xmm15, dword[dodec + r10d * DWORD] ; On prend la valeur du coordonnée Z du point
addss xmm15, [Zo] ; Z + Zo
divss xmm0, xmm15 ; (df * Y) / (Z + Zo)
addss xmm0, [Yo] ; Y' = (df * Y) / (Z + Zo) + Yo

cvtss2si r15d, xmm0 ; On convertie le point en entier
mov dword[y1], r15d ; pour sauvgarder la valeur en y1

inc r13d ; Pour se placer sur le 2ème point de la face
mov r10d, dword[line] ; Utiliser pour trouver X
imul r10d, dword[faces + r13d * DWORD] ; Pour se placer sur X

movss xmm0, [cos_45]
mulss xmm0, dword[dodec + r10d * DWORD] ; X * cos(45)
inc r10d ; Pour se placer sur Y
movss xmm15, [sin_45]
mulss xmm15, dword[dodec + r10d * DWORD] ; Y * sin(45)
subss xmm0, xmm15 ; X = X * cos(45) - Y * sin(45)

mulss xmm0, [df] ; X * df
inc r10d  ; Pour se placer sur Z
movss xmm15, dword[dodec + r10d * DWORD] ; On prend la valeur en coordonnée Z du point
addss xmm15, [Zo] ; Z + Zo
divss xmm0, xmm15 ; (df * Y) / (Z + Zo)
addss xmm0, [Xo] ; X' = (df * X) / (Z + Zo) + Xo

cvtss2si r15d, xmm0 ; On convertie le point en entier
mov dword[x2], r15d ; pour sauvgarder la valeur en x2

dec r10d

movss xmm0, [cos_45]
mulss xmm0, dword[dodec + r10d * DWORD] ; Y * cos(45)
dec r10d ; Pour se placer sur X
movss xmm15, [sin_45]
mulss xmm15, dword[dodec + r10d * DWORD] ; X * sin(45)
addss xmm0, xmm15 ; Y = X * sin(45) + Y * cos(45) 

add r10d, 2
mulss xmm0, [df] ; Y * df
movss xmm15, dword[dodec + r10d * DWORD] ; On prend la valeur en coordonnée Z du point
addss xmm15, [Zo] ; Z + Zo
divss xmm0, xmm15 ; (df * Y) / (Z + Zo)
addss xmm0, [Yo] ; Y' = (df * Y) / (Z + Zo) + Yo

cvtss2si r15d, xmm0 ; On convertie le point en entier
mov dword[y2], r15d ; pour sauvgarder la valeur en y2

inc r13d ; Pour se placer sur le 3ème point de la face
mov r10d, dword[line] ; Utiliser pour trouver X
imul r10d, dword[faces + r13d * DWORD] ; Pour se placer sur X

movss xmm0, [cos_45]
mulss xmm0, dword[dodec + r10d * DWORD] ; X * cos(45)
inc r10d ; Pour se placer sur Y
movss xmm15, [sin_45]
mulss xmm15, dword[dodec + r10d * DWORD] ; Y * sin(45)
subss xmm0, xmm15 ; X = X * cos(45) - Y * sin(45)

mulss xmm0, [df] ; X * df
inc r10d ; Pour se placer sur Z
movss xmm15, dword[dodec + r10d * DWORD] ; On prend la valeur du coordonnée Z du point
addss xmm15, [Zo] ;Z + Zo
divss xmm0, xmm15 ;(df * X) / (Z + Zo)
addss xmm0, [Xo] ;X' = (df * X) / (Z + Zo) + Xo

cvtss2si r15d, xmm0 ; On convertie le point en entier
mov dword[x3], r15d ; pour sauvgarder la valeur en x3

dec r10d ; Pour se placer sur Y

movss xmm0, [cos_45]
mulss xmm0, dword[dodec + r10d * DWORD] ; Y * cos(45)
dec r10d ; Pour se placer sur X
movss xmm15, [sin_45]
mulss xmm15, dword[dodec + r10d * DWORD] ; X * sin(45)
addss xmm0, xmm15 ; Y = X * sin(45) + Y * cos(45) 

add r10d, 2 ; Pour se placer sur Z
mulss xmm0, [df] ; Y * df
movss xmm15, dword[dodec + r10d * DWORD] ; On prend la valeur du coordonnée Z du point
addss xmm15, [Zo] ;Z + Zo
divss xmm0, xmm15 ;(df * X) / (Z + Zo)
addss xmm0, [Yo] ; Y' = (df * Y) / (Z + Zo) + Yo

cvtss2si r15d, xmm0 ; On convertie le point en entier
mov dword[y3], r15d ; pour sauvgarder la valeur en y3

mov eax, dword[x2]
sub eax, dword[x1] ; X21 = X2 - X1
mov dword[x21], eax

mov eax, dword[y2]
sub eax, dword[y1] ; Y21 = Y2 - Y1
mov dword[y21], eax 

mov eax, dword[x3]
sub eax, dword[x1] ; X31 = X3 - X1
mov dword[x31], eax


mov eax, dword[y3]
sub eax, dword[y1] ; Y31 = Y3 - Y1 
mov dword[y31], eax

imul dword[x21] ; result_1 = (X21 * Y31)

mov dword[result_1], eax

mov eax, dword[x31]
imul dword[y21] ; result_2 = (X31 * Y21)

mov dword[result_2], eax
sub dword[result_1], eax ; result_1 = result_1 - result_2

cmp dword[result_1], 0
jg trace ; Si result_1 > 0
jmp check

trace:
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]	; coordonnée source en x
mov r8d,dword[y1]	; coordonnée source en y
mov r9d,dword[x2]	; coordonnée destination en x
push qword[y2]		; coordonnée destination en y
call XDrawLine

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]	; coordonnée source en x
mov r8d,dword[y1]	; coordonnée source en y
mov r9d,dword[x3]	; coordonnée destination en x
push qword[y3]		; coordonnée destination en y
call XDrawLine

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x2]	; coordonnée source en x
mov r8d,dword[y2]	; coordonnée source en y
mov r9d,dword[x3]	; coordonnée destination en x
push qword[y3]		; coordonnée destination en y
call XDrawLine


check:
add r13d, 2 ; Pour se placer sur le 1er point de la face suivante
cmp r13d, 79
ja flush ; Si r13d > 79 Le programme est finit

jmp big_loop ; On continue le tracage

flush:
mov rdi,qword[display_name]
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit