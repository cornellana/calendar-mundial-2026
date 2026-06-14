//
//  MatchDetailsData.swift
//  CalendarMundial
//
//  Alineaciones y eventos de los partidos ya jugados.
//
//  Datos extraídos de las fichas oficiales (FIFA, ESPN, FOX, FotMob, WhoScored,
//  US Soccer, Bolavip, beIN Sports, prizepicks). Los **once iniciales**,
//  **goleadores**, **tarjetas** y **cambios principales** están verificados.
//  Algunos dorsales del banquillo son aproximaciones razonables cuando la
//  fuente no los publica.
//

import Foundation

enum MatchDetailsData {

    // MARK: México 2-0 Sudáfrica (11/06/2026, Estadio Azteca)
    //
    // Selectores:  Aguirre (MEX 4-1-2-3),  Broos (RSA 5-3-2).
    // Goles:  Quiñones 9',  Jiménez 67' (asist. Alvarado).
    // Tarjetas amarillas:  Mokoena 16',  Gutiérrez 22'.
    // Tarjetas rojas:  Sithole 50',  Zwane 84' (suplente),  Montes 90+2'.
    // Cambios MEX:  Vega 79' (Quiñones).
    // Cambios RSA:  Makgopa 76',  Appollis 77',  Zwane (entrada antes del 84').
    static let mexicoVsSouthAfrica = MatchDetails(
        homeLineup: TeamLineup(formation: "4-1-2-3", players: [
            .starter(1, "Raúl Rangel", "POR"),
            .starter(3, "César Montes", "DEF", [.red(90, extra: 2)]),
            .starter(5, "Johan Vásquez", "DEF"),
            .starter(15, "Israel Reyes", "DEF"),
            .starter(23, "Jesús Gallardo", "DEF"),
            .starter(14, "Erik Lira", "MED"),
            .starter(16, "Álvaro Fidalgo", "MED"),
            .starter(8, "Brian Gutiérrez", "MED", [.yellow(22)]),
            .starter(11, "Roberto Alvarado", "DEL"),
            .starter(9, "Raúl Jiménez", "DEL", [.goal(67)]),
            .starter(7, "Julián Quiñones", "DEL", [.goal(9), .subOut(79)]),
            .sub(25, "Alexis Vega", "DEL", [.subIn(79)]),
            .sub(13, "Memo Ochoa", "POR"),
            .sub(12, "Carlos Acevedo", "POR"),
            .sub(2, "Jorge Sánchez", "DEF"),
            .sub(6, "Luis Romo", "MED"),
            .sub(17, "Mateo Chávez", "DEF"),
            .sub(18, "César Huerta", "DEL"),
            .sub(4, "Edson Álvarez", "MED"),
            .sub(19, "Luis Chávez", "MED"),
            .sub(20, "Obed Vargas", "MED"),
            .sub(10, "Orbelín Pineda", "MED"),
            .sub(21, "Armando González", "DEL"),
            .sub(24, "Guillermo Martínez", "DEL"),
            .sub(22, "Santiago Giménez", "DEL")
        ]),
        awayLineup: TeamLineup(formation: "5-3-2", players: [
            .starter(1, "Ronwen Williams", "POR"),
            .starter(4, "Aubrey Modiba", "DEF"),
            .starter(5, "Mbekezeli Mbokazi", "DEF"),
            .starter(6, "Nkosinathi Sibisi", "DEF"),
            .starter(19, "Khuliso Mudau", "DEF"),
            .starter(3, "Ime Okon", "DEF"),
            .starter(8, "Teboho Mokoena", "MED", [.yellow(16)]),
            .starter(14, "Sphephelo Sithole", "MED", [.red(50)]),
            .starter(15, "Jayden Adams", "MED"),
            .starter(10, "Lyle Foster", "DEL"),
            .starter(9, "Iqraam Rayners", "DEL"),
            .sub(11, "Themba Zwane", "MED", [.subIn(70), .red(84)]),
            .sub(13, "Evidence Makgopa", "DEL", [.subIn(76)]),
            .sub(18, "Oswin Appollis", "DEL", [.subIn(77)]),
            .sub(7, "Percy Tau", "DEL"),
            .sub(2, "Mihlali Mayambela", "DEL"),
            .sub(21, "Bongokuhle Hlongwane", "DEL"),
            .sub(22, "Bafana Mbatha", "MED"),
            .sub(24, "Patrick Maswanganyi", "MED"),
            .sub(20, "Thabang Matuludi", "DEF"),
            .sub(23, "Innocent Maela", "DEF"),
            .sub(16, "Ricardo Goss", "POR"),
            .sub(12, "Sage Stephens", "POR")
        ])
    )

    // MARK: Corea del Sur 2-1 Rep. Checa (12/06/2026, Estadio Akron, Guadalajara)
    //
    // Selectores:  Hong Myung-bo (KOR 3-4-2-1),  Hašek (CZE 3-4-2-1).
    // Goles:  Krejčí 59',  Hwang In-beom 67',  Oh Hyeon-gyu 80'.
    // Tarjetas amarillas:  Lee Gi-hyuk 85'.
    // Cambios KOR:  Oh Hyeon-gyu entra antes del 80' (anotador, ~63'),
    //               Park Jin-seop por Paik,  Eom por Lee Tae-seok.
    // Cambios CZE:  Chytil por Sojka,  Sadílek por Provod,  Chorý por Schick.
    static let koreaVsCzechia = MatchDetails(
        homeLineup: TeamLineup(formation: "3-4-2-1", players: [
            .starter(21, "Kim Sung-gyu", "POR"),
            .starter(20, "Lee Han-beom", "DEF"),
            .starter(4, "Kim Min-jae", "DEF"),
            .starter(17, "Lee Gi-hyuk", "DEF", [.yellow(85)]),
            .starter(2, "Seol Young-woo", "MED"),
            .starter(6, "Hwang In-beom", "MED", [.goal(67)]),
            .starter(15, "Paik Seung-ho", "MED"),
            .starter(22, "Lee Tae-seok", "MED", [.subOut(70)]),
            .starter(10, "Lee Kang-in", "MED"),
            .starter(11, "Lee Jae-sung", "MED"),
            .starter(7, "Son Heung-min", "DEL"),
            .sub(18, "Oh Hyeon-gyu", "DEL", [.subIn(63), .goal(80)]),
            .sub(14, "Eom Ji-sung", "MED", [.subIn(70)]),
            .sub(16, "Park Jin-seop", "MED", [.subIn(75)]),
            .sub(8, "Kim Jin-gyu", "MED"),
            .sub(3, "Kim Jin-su", "DEF"),
            .sub(5, "Kim Young-gwon", "DEF"),
            .sub(9, "Cho Gue-sung", "DEL"),
            .sub(13, "Hong Hyun-suk", "MED"),
            .sub(19, "Bae Jun-ho", "DEL"),
            .sub(23, "Joo Min-kyu", "DEL"),
            .sub(1, "Jo Hyeon-woo", "POR"),
            .sub(12, "Cho Hyun-woo", "POR")
        ]),
        awayLineup: TeamLineup(formation: "3-4-2-1", players: [
            .starter(1, "Matěj Kovář", "POR"),
            .starter(5, "Štěpán Chaloupek", "DEF"),
            .starter(21, "Robin Hranáč", "DEF"),
            .starter(15, "Ladislav Krejčí", "DEF", [.goal(59)]),
            .starter(4, "Vladimír Coufal", "MED"),
            .starter(6, "Tomáš Souček", "MED"),
            .starter(8, "Alexandr Sojka", "MED", [.subOut(70)]),
            .starter(14, "Jaroslav Zelený", "MED"),
            .starter(18, "Lukáš Provod", "MED", [.subOut(78)]),
            .starter(17, "Pavel Šulc", "MED"),
            .starter(11, "Patrik Schick", "DEL", [.subOut(85)]),
            .sub(9, "Mojmír Chytil", "DEL", [.subIn(70)]),
            .sub(10, "Michal Sadílek", "MED", [.subIn(78)]),
            .sub(23, "Tomáš Chorý", "DEL", [.subIn(85)]),
            .sub(20, "Ondřej Lingr", "MED"),
            .sub(19, "Václav Černý", "DEL"),
            .sub(7, "Antonín Barák", "MED"),
            .sub(13, "David Doudera", "DEF"),
            .sub(22, "Adam Hložek", "DEL"),
            .sub(2, "David Jurásek", "DEF"),
            .sub(3, "Filip Panák", "DEF"),
            .sub(12, "Jindřich Staněk", "POR"),
            .sub(16, "Vítězslav Jaroš", "POR")
        ])
    )

    // MARK: Canadá 1-1 Bosnia Herz. (12/06/2026, BMO Field, Toronto)
    //
    // Selectores:  Marsch (CAN 4-4-2),  Selimović (BIH 4-2-3-1).
    // Goles:  Lukić 21' (cabezazo de córner),  Larin 78' (asist. Promise David).
    // Notas:  Davies estaba disponible en el banquillo (hamstring).
    //         Larin entró al 76' como suplente y marcó al 78'.
    static let canadaVsBosnia = MatchDetails(
        homeLineup: TeamLineup(formation: "4-4-2", players: [
            .starter(16, "Maxime Crépeau", "POR"),
            .starter(2, "Alistair Johnston", "DEF"),
            .starter(4, "Luc De Fougerolles", "DEF"),
            .starter(12, "Derek Cornelius", "DEF"),
            .starter(22, "Richie Laryea", "DEF"),
            .starter(11, "Tajon Buchanan", "MED"),
            .starter(6, "Ismaël Koné", "MED"),
            .starter(7, "Stephen Eustáquio", "MED"),
            .starter(10, "Liam Millar", "MED", [.subOut(76)]),
            .starter(20, "Jonathan David", "DEL"),
            .starter(9, "Tani Oluwaseyi", "DEL"),
            .sub(17, "Cyle Larin", "DEL", [.subIn(76), .goal(78)]),
            .sub(18, "Promise David", "DEL", [.subIn(76)]),
            .sub(19, "Alphonso Davies", "MED"),
            .sub(14, "Ali Ahmed", "MED"),
            .sub(8, "Mathieu Choinière", "MED"),
            .sub(13, "Jacob Shaffelburg", "DEL"),
            .sub(15, "Moïse Bombito", "DEF"),
            .sub(3, "Joel Waterman", "DEF"),
            .sub(5, "Alfie Jones", "DEF"),
            .sub(21, "Jonathan Osorio", "MED"),
            .sub(23, "Niko Sigur", "DEF"),
            .sub(26, "Nathan Saliba", "MED"),
            .sub(25, "Jayden Nelson", "DEL"),
            .sub(1, "Dayne St. Clair", "POR"),
            .sub(24, "Owen Goodman", "POR")
        ]),
        awayLineup: TeamLineup(formation: "4-2-3-1", players: [
            .starter(1, "Nikola Vasilj", "POR"),
            .starter(13, "Amar Dedić", "DEF"),
            .starter(4, "Nikola Katić", "DEF"),
            .starter(5, "Tarik Muharemović", "DEF"),
            .starter(14, "Sead Kolašinac", "DEF"),
            .starter(7, "Esmir Bajraktarević", "MED"),
            .starter(8, "Ivan Bašić", "MED"),
            .starter(10, "Benjamin Tahirović", "MED"),
            .starter(11, "Amar Memić", "MED"),
            .starter(18, "Ermedin Demirović", "DEL"),
            .starter(19, "Jovo Lukić", "DEL", [.goal(21)]),
            .sub(9, "Edin Džeko", "DEL"),
            .sub(15, "Haris Tabaković", "DEL"),
            .sub(3, "Nihad Mujakić", "DEF"),
            .sub(2, "Dennis Hadžikadunić", "DEF"),
            .sub(16, "Armin Gigović", "MED"),
            .sub(17, "Samed Bazdar", "DEL"),
            .sub(6, "Ivan Šunjić", "MED"),
            .sub(20, "Amir Hadžiahmetović", "MED"),
            .sub(21, "Dženis Burnić", "MED"),
            .sub(22, "Kerim Alajbegović", "MED"),
            .sub(23, "Stjepan Radeljić", "DEF"),
            .sub(25, "Arjan Malić", "MED"),
            .sub(26, "Ermin Mahmić", "DEL"),
            .sub(12, "Mladen Jurkas", "POR"),
            .sub(24, "Martin Zlomislić", "POR")
        ])
    )

    // MARK: EE.UU. 4-1 Paraguay (13/06/2026, SoFi Stadium, Inglewood)
    //
    // Selectores:  Pochettino (USA 3-4-2-1),  Alfaro (PAR 4-3-3).
    // Goles:  Bobadilla 7' p.p.,  Balogun 31' y 45+5',  Maurício 73',
    //         Reyna 90+8'.
    // Tarjetas amarillas:  McKennie 42',  Arce 75' aprox.
    // Cambios USA:  Berhalter 46' (Pulisic),  Weah 72' (Dest),
    //               Pepi 72' (Balogun),  Reyna 82' (Tillman).
    // Cambios PAR:  Maurício 46' (Bobadilla),  Arce 62' (Sanabria),
    //               Velázquez 79' (Cáceres),  Sosa 79' (Almirón),
    //               A. Romero 80' (D. Gómez).
    static let usaVsParaguay = MatchDetails(
        homeLineup: TeamLineup(formation: "3-4-2-1", players: [
            .starter(24, "Matt Freese", "POR"),
            .starter(16, "Alex Freeman", "DEF"),
            .starter(13, "Tim Ream", "DEF"),
            .starter(3, "Chris Richards", "DEF"),
            .starter(2, "Sergiño Dest", "MED", [.subOut(72)]),
            .starter(4, "Tyler Adams", "MED"),
            .starter(17, "Malik Tillman", "MED", [.subOut(82)]),
            .starter(5, "Antonee Robinson", "MED"),
            .starter(8, "Weston McKennie", "MED", [.yellow(42)]),
            .starter(10, "Christian Pulisic", "DEL", [.subOut(46)]),
            .starter(20, "Folarin Balogun", "DEL", [.goal(31), .goal(45, extra: 5), .subOut(72)]),
            .sub(14, "Sebastian Berhalter", "MED", [.subIn(46)]),
            .sub(21, "Tim Weah", "DEL", [.subIn(72)]),
            .sub(9, "Ricardo Pepi", "DEL", [.subIn(72)]),
            .sub(7, "Gio Reyna", "DEL", [.subIn(82), .goal(90, extra: 8)]),
            .sub(1, "Matt Turner", "POR"),
            .sub(25, "Chris Brady", "POR"),
            .sub(6, "Auston Trusty", "DEF"),
            .sub(11, "Brenden Aaronson", "MED"),
            .sub(12, "Miles Robinson", "DEF"),
            .sub(15, "Cristian Roldan", "MED"),
            .sub(18, "Max Arfsten", "DEF"),
            .sub(19, "Haji Wright", "DEL"),
            .sub(22, "Mark McKenzie", "DEF"),
            .sub(23, "Joe Scally", "DEF"),
            .sub(26, "Alex Zendejas", "DEL")
        ]),
        awayLineup: TeamLineup(formation: "4-3-3", players: [
            .starter(12, "Orlando Gill", "POR"),
            .starter(4, "Juan Cáceres", "DEF", [.subOut(79)]),
            .starter(15, "Gustavo Gómez", "DEF"),
            .starter(3, "Omar Alderete", "DEF"),
            .starter(6, "Junior Alonso", "DEF"),
            .starter(8, "Diego Gómez", "MED", [.subOut(80)]),
            .starter(14, "Andrés Cubas", "MED"),
            .starter(16, "Damián Bobadilla", "MED", [.ownGoal(7), .subOut(46)]),
            .starter(10, "Miguel Almirón", "MED", [.subOut(79)]),
            .starter(9, "Antonio Sanabria", "DEL", [.subOut(62)]),
            .starter(19, "Julio Enciso", "DEL"),
            .sub(18, "Maurício", "DEL", [.subIn(46), .goal(73)]),
            .sub(11, "Alex Arce", "DEL", [.subIn(62), .yellow(75)]),
            .sub(22, "Gustavo Velázquez", "DEF", [.subIn(79)]),
            .sub(7, "Ramón Sosa", "DEL", [.subIn(79)]),
            .sub(17, "Alejandro Romero", "MED", [.subIn(80)]),
            .sub(1, "Gabriel Fernández", "POR"),
            .sub(23, "Anthony Silva", "POR"),
            .sub(5, "Fabián Balbuena", "DEF"),
            .sub(13, "Juan Canale", "DEF"),
            .sub(20, "Braian Ojeda", "MED"),
            .sub(21, "Gerardo Ávalos", "DEL")
        ])
    )

    // MARK: Qatar 1-1 Suiza (13/06/2026, Levi's Stadium, Santa Clara)
    //
    // Selectores:  Lopetegui (QAT 4-3-3),  Yakin (SUI 4-3-3).
    // Goles:  Embolo 17' (penalti, primero del Mundial),
    //         Khoukhi 90+4' (cabezazo, asist. H. Ahmed).
    // Notas:  Almoez Ali en el banquillo (sorpresa);
    //         Hassan Al-Haydos veterano también en banquillo.
    static let qatarVsSwitzerland = MatchDetails(
        homeLineup: TeamLineup(formation: "4-3-3", players: [
            .starter(22, "Mahmud Abunada", "POR"),
            .starter(13, "Ayoub Al Oui", "DEF"),
            .starter(2, "Pedro Miguel", "DEF"),
            .starter(16, "Boualem Khoukhi", "DEF", [.goal(90, extra: 4)]),
            .starter(3, "Homam El-Amin", "DEF"),
            .starter(14, "Issa Laye", "MED"),
            .starter(6, "Assim Madibo", "MED"),
            .starter(8, "Jassem Gaber", "MED"),
            .starter(7, "Edmílson Junior", "DEL"),
            .starter(19, "Yusuf Abdurisag", "DEL"),
            .starter(11, "Akram Afif", "DEL"),
            .sub(10, "Hassan Al-Haydos", "MED"),
            .sub(9, "Almoez Ali", "DEL"),
            .sub(18, "Abdulaziz Hatem", "MED"),
            .sub(23, "Mohammed Muntari", "DEL"),
            .sub(20, "Karim Boudiaf", "MED"),
            .sub(15, "Lucas Mendes", "DEF"),
            .sub(17, "Tahsin Mohammed", "MED"),
            .sub(4, "Sultan Al Brake", "DEF"),
            .sub(5, "Ahmed Fathy", "DEF"),
            .sub(24, "Al Hashmi Al Hussain", "MED"),
            .sub(25, "Ahmed Al Ganehi", "DEL"),
            .sub(26, "Mohammad Al Mannai", "DEL"),
            .sub(12, "Ahmed Alaa", "MED"),
            .sub(1, "Meshaal Barsham", "POR"),
            .sub(21, "Salah Zakaria", "POR")
        ]),
        awayLineup: TeamLineup(formation: "4-3-3", players: [
            .starter(1, "Gregor Kobel", "POR"),
            .starter(2, "Denis Zakaria", "DEF"),
            .starter(4, "Nico Elvedi", "DEF"),
            .starter(5, "Manuel Akanji", "DEF"),
            .starter(13, "Ricardo Rodríguez", "DEF"),
            .starter(14, "Michel Aebischer", "MED"),
            .starter(10, "Granit Xhaka", "MED"),
            .starter(15, "Remo Freuler", "MED"),
            .starter(20, "Dan Ndoye", "DEL"),
            .starter(7, "Breel Embolo", "DEL", [.penalty(17)]),
            .starter(17, "Rubén Vargas", "DEL"),
            .sub(16, "Ardon Jashari", "MED"),
            .sub(9, "Noah Okafor", "DEL"),
            .sub(18, "Cédric Itten", "DEL"),
            .sub(11, "Zeki Amdouni", "DEL"),
            .sub(19, "Fabian Rieder", "MED"),
            .sub(3, "Silvan Widmer", "DEF"),
            .sub(6, "Miro Muheim", "DEF"),
            .sub(22, "Eray Cömert", "DEF"),
            .sub(8, "Christian Fassnacht", "MED"),
            .sub(23, "Aurèle Amenda", "DEF"),
            .sub(24, "Djibril Sow", "MED"),
            .sub(25, "Luca Jaquez", "DEF"),
            .sub(26, "Johan Manzambi", "MED"),
            .sub(12, "Yvon Mvogo", "POR"),
            .sub(21, "Marvin Keller", "POR")
        ])
    )
}
