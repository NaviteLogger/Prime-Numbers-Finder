section .text
    org 100h

start:
    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx

    call get_input       ; Pobierz zakres od użytkownika
    mov dx, after_input
    call print_string
    call new_line
    call find_primes     ; Znajdź liczby pierwsze
    jmp start            ; Powtarzaj operację dla nowych zakresów

    mov ah, 0x4c 
    int 21h

;----------------------------------------------
; Procedura: get_input
; Pobiera zakres od użytkownika
;----------------------------------------------
get_input:
    ; Pobierz minimalną wartość
    mov dx, prompt1        ; 1. Załaduj adres `prompt1` do rejestru DX
    call print_string      ; 2. Wywołaj procedurę `print_string` (wypisuje "Enter min value:")
    call get_number        ; 3. Wywołaj procedurę `get_number`, aby pobrać liczbę od użytkownika

    ; Zapisz wartość w zmiennej `min`
    mov [min], bx          ; 4. Zapisz wartość z rejestru AX do zmiennej `min`
    mov bx, 0              ; 5. Wyzeruj BX

    ; Pobierz maksymalną wartość
    mov dx, prompt2
    call print_string
    call get_number
    mov [max], bx    ; Zapisz wartość w `max`

    ; Sprawdź, czy min < max
    mov ax, [min]
    cmp ax, [max]
    jge invalid_range

    ; Debugowanie to moja pasja
    mov dx, valid_range
    call print_string
    call new_line

    ret

invalid_range:
    mov dx, invalid_range_msg
    call print_string
    call new_line
    
    jmp get_input
    

;----------------------------------------------
; Procedura: find_primes
; Znajduje liczby pierwsze w zadanym przedziale
;----------------------------------------------
find_primes:
    mov ax, [min] ; Zaczynamy od dolnej granicy
    jmp next_number
    
next_number:
    cmp ax, [max]    ; Czy dojechaliśmy za górną granicę?
    jg done          ; Jeśli tak, zakończ

    push ax          ; Zachowaj wartość na stosie
    call is_prime    ; Sprawdź, czy liczba jest pierwsza
    pop ax           ; Przywróć wartość ze stosu

    cmp bx, 1        ; Jeśli BX = 1, to liczba jest pierwsza
    jne skip_number

    ; Wyświetl liczbę pierwszą
    mov dx, prime_msg
    call print_string
    
    mov dx, ax
    call print_number
    call new_line
    jmp skip_number

skip_number:
    inc ax           ; Przejdź do następnej liczby
    jmp next_number

done:
    ret

;----------------------------------------------
; Procedura: is_prime
; Sprawdza, czy liczba w AX jest pierwsza
; Zwraca wynik w BX (1 = pierwsza, 0 = niepierwsza)
;----------------------------------------------
is_prime:
    mov bx, 2  ; bx - pierwszy dzielnik
    
    cmp ax, 1  ; 1 nie jest liczbą pierwszą
    jng not_a_prime

    mov cx, ax ; cx - górna granica dzielników
    jmp check_divisor

check_divisor:
    cmp bx, cx
    jge prime_found   ; Jeśli bx >= cx, liczba jest pierwsza

    ; Sprawdź, czy ax jest podzielne przez bx
    mov ax, cx
    mov dx, 0
    div bx
    
    cmp dx, 0
    je not_a_prime    ; Jeśli reszta = 0, to liczba nie jest pierwsza

    inc bx            ; Sprawdź kolejny dzielnik
    jmp check_divisor

prime_found:
    mov bx, 1         ; Liczba jest pierwsza
    ret

not_a_prime:
    mov bx, 0         ; Liczba nie jest pierwsza
    ret

;----------------------------------------------
; Procedura: get_number
; Pobiera liczbę od użytkownika
; Zwraca wynik w AX
;----------------------------------------------
get_number:
    xor ax, ax         ; Wyzeruj AX, aby nie było śmieci
    xor bx, bx         ; Wyzeruj BX (będzie używany do przechowywania liczby)

read_digit:
    mov ah, 1          ; Funkcja DOS do odczytu znaku z klawiatury
    int 21h            ; Pobierz znak od użytkownika
    mov ah, 0          ; Wyzeruj rejestr AH
    
    cmp al, 13         ; Sprawdź, czy Enter (kod ASCII 13)
    je done_input      ; Jeśli Enter, zakończ wczytywanie

    ; Idiotoodporność
    cmp al, "0"        ; Sprawdź, czy znak jest cyfrą
    jl invalid_input   ; Jeśli nie, zignoruj

    cmp al, "9"        ; Sprawdź, czy znak jest cyfrą
    jg invalid_input   ; Jeśli nie, zignoruj

    sub al, "0"        ; Konwertuj znak ASCII na cyfrę
    push bx            ; Zachowaj wartość na stosie
    imul bx, 10        ; Przesuń w lewo bx o 1 miejsce   
    
    ; Dodanie dx do ax
    add bx, ax         ; Dodaj wartość do BX
    pop cx             ; Odczytaj wartość ze stosu

    cmp bx, cx         ; Sprawdź, czy nowa wartość mieści się w 16 bitach
    jl overflow  ; Jeśli nie, zignoruj

    jmp read_digit     ; Kontynuuj wczytywanie kolejnych cyfr
    
overflow:
    call new_line
    mov dx, overflow_msg
    call print_string
    call new_line
    jmp start
    
invalid_input:
    call new_line
    mov dx, invalid_char_msg
    call print_string
    call new_line
    jmp start


done_input:
    ret

;----------------------------------------------
; Procedura: print_string
; Wypisuje string zakończony znakiem $
;----------------------------------------------
print_string:
    push ax
    mov ah, 9
    int 21h
    pop ax
    ret

;----------------------------------------------
; Procedura: print_number
; Wypisuje liczbę z AX
;----------------------------------------------
print_number:
    push ax
    mov bx, 10
    jmp print_digit
    
print_digit:
    mov ax, dx
    xor dx, dx
    div bx ; Ax - to co wypisujemy, dx - reszta, którą wypiszemy później

    cmp ax, 0
    je end_print_digit

    push dx ; Zachowanie reszty na stosie
    
    mov dx, ax
    add dx, "0"    ; Konwersja cyfry na znak
    ; mov dx, test_msg
    mov ah, 2
    int 21h

    pop dx ; Odczytanie reszty ze stosu

    
    jmp print_digit

end_print_digit:
    add dx, "0"
    mov ah, 2
    int 21h

    pop ax
    ret

;----------------------------------------------
; Procedura: new_line
; Wypisuje nową linię
;----------------------------------------------
new_line:
    mov dx, newline
    call print_string
    ret

;----------------------------------------------
; Sekcja .data - inicjalizowane zmienne
;----------------------------------------------
section .data
    prompt1 db "Enter min value: $"
    prompt2 db "Enter max value: $"
    valid_range db "Valid range!$"
    overflow_msg db "Number is too large. Please enter a smaller number.$"
    test_msg db "Test if it works $"
    after_input db "Proceeding to find primes...$"
    debug_ax_value db "AX before saving to min: $"
    invalid_char_msg db "Invalid character entered. Please enter digits only.$"
    invalid_range_msg db "Invalid range. Please enter min < max.$"
    prime_msg db "Prime: $"
    newline db 13, 10, '$'

;----------------------------------------------
; Sekcja .bss - niezainicjalizowane zmienne
;----------------------------------------------
section .bss
    min resb 2
    max resb 2