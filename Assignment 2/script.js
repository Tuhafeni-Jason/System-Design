 // Update date
        function updateDate() {
            const dateElement = document.getElementById('date');
            const now = new Date();
            dateElement.textContent = now.toLocaleDateString('en-US', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            });
        }

        // Update time every second
        function updateTime() {
            const timeElement = document.getElementById('time');
            const now = new Date();
            timeElement.textContent = now.toLocaleTimeString('en-US', {
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            });
        }

        // Generate calendar for current month
        function generateCalendar() {
            const calendar = document.getElementById('calendar');
            const now = new Date();
            const year = now.getFullYear();
            const month = now.getMonth();
            const monthName = now.toLocaleString('default', { month: 'long' });
            const daysInMonth = new Date(year, month + 1, 0).getDate();
            const firstDayOfMonth = new Date(year, month, 1).getDay();

            let table = '<table>';
            table += `<caption>${monthName} ${year}</caption>`;
            table += '<tr><th>Sun</th><th>Mon</th><th>Tue</th><th>Wed</th><th>Thu</th><th>Fri</th><th>Sat</th></tr>';
            table += '<tr>';

            // Add empty cells for days before the first of the month
            for (let i = 0; i < firstDayOfMonth; i++) {
                table += '<td></td>';
            }

            // Add days of the month
            for (let day = 1; day <= daysInMonth; day++) {
                const isToday = day === now.getDate();
                table += `<td>${isToday ? '<strong>' + day + '</strong>' : day}</td>`;
                if ((day + firstDayOfMonth) % 7 === 0) {
                    table += '</tr><tr>';
                }
            }

            // Fill remaining cells in the last row if needed
            const remainingCells = (7 - ((daysInMonth + firstDayOfMonth) % 7)) % 7;
            for (let i = 0; i < remainingCells; i++) {
                table += '<td></td>';
            }

            table += '</tr></table>';
            calendar.innerHTML = table;
        }

        // Initialize everything
        updateDate();
        updateTime();
        generateCalendar();

        // Update time every second
        setInterval(updateTime, 1000);