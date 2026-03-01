### Engineering Experience

**1. Describe a skill or knowledge you acquired recently that has been impactful for you.**
A recent impactful skill I acquired is AWS architecture. My company sponsored me to study for the AWS Solutions Architect - Associate exam. I made this investment to shift my perspective from purely application development to understanding infrastructure failure domains and system design. The outcome has been significant: during sprint planning, I can now identify architectural complexities early and propose simpler, more reliable alternatives. For example, instead of defaulting to a complex multi service cloud deployment for a recent personal project, I modeled the failure domains and utilized a self-hosted environment on my Arch Linux machine using Cloudflare tunnels and Dokploy. I established an automated Git push deployment pipeline that handles multiple local backends connected to a Vercel hosted frontend, prioritizing operational simplicity over unnecessary cloud overhead.

**2. What new skill would you like to learn?**
I am actively expanding my knowledge of Cybersecurity, specifically focusing on threat modeling and the CVE lifecycle. Recently, there has been an industry push toward rapid development workflows often aided by AI which frequently bypass deliberate security reviews. During a company hackathon, my team built a Chrome extension to perform automated penetration testing on our internal web applications. I designed an event driven system where the frontend sent URLs via WebSockets to a message queue, which a Python worker picked up to execute OWASP ZAP API tests asynchronously. While we didn't win, the project highlighted how easily supply chain vulnerabilities and injection flaws can compromise seemingly stable apps. Given my Master’s background in Computer Architecture, I want to master security at the systems level so I can build software that is structurally resilient, not just feature complete.

**3. What kinds of software projects have you worked on before?**
I have built software across the entire stack, which I mentally categorize into three areas: systems, applications, and infrastructure. 
*   **Systems & Infrastructure:** My primary environment is Arch Linux. I use Btrfs snapshots for atomic rollbacks and recently migrated to Wayland (Hyprland) to mitigate X11 remote keystroke vulnerabilities and screen tearing. I regularly write systemd services and manage Docker networking for local deployments.
*   **Applications:** I build backends primarily in Python (FastAPI) and TypeScript, dropping to C++ when low level memory management is required. 
*   **Data/AI:** I have built deep learning models and RAG applications utilizing Postgres, Elasticsearch, and FAISS for vector search.

**4. Why Python, and what’s your history with this language?**
Python strikes the perfect balance between developer velocity and system maintainability. I began using it after my 12th grade board exams for data visualization (Matplotlib), which naturally evolved into predictive analytics during my Master's degree. Over time, my approach to Python has matured from writing simple automation scripts to engineering robust backend systems. Today, I treat Python craftsmanship seriously. I rely heavily on type hints, static analysis (`mypy`), and `pydantic` to enforce data validation at the boundaries of my applications. I prefer unopinionated, asynchronous frameworks like FastAPI over heavy frameworks like Django, as they allow me to dictate the system architecture rather than fighting the framework.

**5. Would you describe yourself as a high quality coder? Why?**
Yes. I view code not as an asset, but as a liability that must be maintained. High quality coding is about long term engineering judgment, not just closing Jira tickets. I consistently reduce system bug counts by breaking complex logic into modular, testable units. I actively utilize Behavior Driven Development (BDD) to write comprehensive unit and integration tests (using `pytest`). Furthermore, I frequently take the initiative to debug and refactor legacy code out of my immediate scope, simply because I understand that reducing technical debt today prevents critical outages tomorrow. 

**6. Would you describe yourself as an architect of resilient software?**
Yes. When designing a system, I evaluate it across distinct axes: Database, Caching, Scaling, Delegation, Concurrency, and Communication. A core principle I follow is designing for graceful degradation. For example, I architected a personal observability dashboard aggregating webhooks, health checks, and financial data using a Pub/Sub model. I explicitly designed the system so that if an external API rate limits or a webhook fails, the event queue safely retries without crashing the main application thread. Anticipating failure, rather than hoping for perfection, is how I guarantee resilience.

**7. What software products have you yourself led which shipped many releases to multiple customers?**
I led a critical initiative to embed a Unity game instance inside a React Native mobile application. My initial architectural approach was a failure: I started off by loading the Unity build via a WebView. Under load, this approach was severely laggy, dropping below 30 FPS on real devices with unacceptable input lag due to browser engine overhead. Realizing the web layer was the wrong tool for native rendering, I completely pivoted the architecture. Instead, I exported the Unity builds as standalone native libraries for Android and iOS and wrote custom bridge code to communicate directly with the React Native thread. While this solved the performance bottleneck, it introduced severe background memory leaks. By aggressively profiling the hardware allocation and strictly managing the native lifecycle of the Unity instance, we eliminated the memory leaks and eventually achieved a 99.99% crash free session rate across multiple customer releases.

**8. What is your most senior role in a software engineering organisation?**
My most senior role has been as a Lead Engineer on specific, high stakes projects, such as the Unity integration mentioned above. In this capacity, my span of control included leading the daily technical direction of the mobile developers. I instituted mandatory daily PR review sessions where we analyzed the code line by line, focusing explicitly on resource consumption, architectural tradeoffs, and eliminating premature optimizations before merging.

**9. What is your proudest success as an engineering leader?**
My proudest success was resolving the Unity escalation. After pivoting away from the failed WebView approach and spending days systematically profiling memory allocation eliminating variables one by one rather than guessing I finally isolated and patched the core native memory leak at 3:00 AM. The build stabilized perfectly. I was congratulated by the CEO, co founders, and engineering managers, and received a company wide Impact Award. The real success, however, was proving that disciplined, methodical debugging and a willingness to scrap a failing architecture always beats panicked hot fixing.

**10. Outline your thoughts on open source software development.**
Open source is the foundation of modern infrastructure. While my direct upstream commits to major open source projects are currently limited, I operate with an open source maintainer's mindset. I frequently read the source code of the tools I use to understand their internal mechanics and debug issues rather than relying solely on documentation. Inside my company, I champion open source practices: enforcing strict CI/CD, requiring thorough PR descriptions, and maintaining high quality internal documentation. I strongly believe that the health of an open source project is dictated by its triage process, issue management, and the architectural clarity of its core maintainers.

**11. Describe your experience building large systems with many services.**
I contributed to the backend architecture for "QCare," a government backed PG management system for college students in Kenya. A critical architectural tradeoff I managed was designing the authentication platform. Rather than relying on a heavy third party identity provider, I implemented a custom, highly secure cookie based JWT authentication system with MFA. I designed a strict Role Based Access Control (RBAC) and refresh token rotation system to isolate security boundaries. I also integrated event driven components, such as DocuSign webhooks that automatically triggered digital signature workflows upon student registration. 

**12. How comprehensive would you say your knowledge of a Linux distribution is?**
My knowledge is highly systems oriented. Arch Linux has been my daily driver for four years, which forces an intimate understanding of Linux internals. I regularly interact with the system layer: writing and debugging `systemd` unit files, managing Linux namespaces, and investigating userspace behavior using `strace`, `lsof`, and `htop`. I also have practical experience with the Linux packaging ecosystem. I build software from source using Makefiles and write `PKGBUILDs` for `pacman`, which has given me a deep appreciation for dependency resolution, shared libraries, and how software fundamentally integrates into a distribution.

**13. Describe your experience with large scale IT operations, SAAS, or devops.**
My approach to DevOps is rooted in an operational reliability mindset. Beyond deploying code, I focus on how software behaves in a running environment. I manage a suite of self hosted containerized services, which has given me hands on experience dealing with raw infrastructure issues such as diagnosing and resolving a Btrfs filesystem mounting failure on a degraded disk. I build and maintain my own CI/CD pipelines, ensuring that test coverage and static analysis act as strict gates before any code reaches a production state.

**14. Describe your experience with public cloud based operations.**
Through my AWS training and practical engineering, I understand how to manage public cloud estates with a focus on security and networking. I am familiar with defining secure VPC boundaries, managing IAM roles based on the principle of least privilege, and utilizing Infrastructure as Code (IaC) principles. I strongly believe that a great developer experience in the cloud means infrastructure should be invisible to the application developer, driven entirely by automated deployment pipelines.

**15. Outline your thoughts on quality in software development.**
Quality is not an accident; it is the result of rigorous, automated enforcement. The most effective practices are integrating static analysis, type checking, and automated testing (unit and integration) directly into the CI/CD pipeline so that bad code physically cannot be merged. Peer review is equally critical, not just for catching bugs, but for ensuring architectural alignment.

**16. Outline your thoughts on documentation.**
Documentation scales engineering. As teams increasingly rely on LLMs to assist with code comprehension, accurate, markdown based documentation is more critical than ever. The Arch Wiki is the ultimate standard for open source documentation it is so structurally sound and technically precise that engineers use it to debug entirely different Linux distributions. Teams should treat documentation as code: version controlled, peer reviewed, and stored closely to the source.

**17. Outline your thoughts on user experience, usability and design.**
Excellent UX hides engineering complexity from the user. I recently built a mobile invoicing application for my father. Because he is not highly technical, I had to aggressively simplify the UI, stripping away all unnecessary features and focusing strictly on his core workflows (creating contacts, logging products, viewing analytics). To deliver outstanding UX, an engineer must have deep empathy for the user and an unwillingness to expose internal system logic to the frontend.

**18. Outline your thoughts on performance in software engineering.**
Performance is an architectural feature. I ensure products are fast by testing them on heavily constrained hardware and low end devices, rather than relying on developer grade machines. I use profiling tools to identify bottlenecks in memory allocation and CPU cycles, and I simulate network throttling to ensure the application degrades gracefully under poor conditions. Performance should be measured objectively via metrics, not subjectively by "feel."

**19. Outline your thoughts on security.**
Security must be implemented at the systems layer, not patched on at the end. To improve security posture, engineers must understand the attack vectors of their dependencies. I lead by example: integrating automated vulnerability scanning (like OWASP ZAP) into pipelines, implementing strict boundary validations (e.g., Pydantic in Python), and actively monitoring the CVE lifecycle of the open source packages we consume.

**20. Outline your thoughts on devops and devsecops.**
Effective DevOps is about reproducible, immutable deployments. What is effective is automated testing, containerization, and infrastructure as code. What is highly overrated is adopting hyper complex orchestration tools (like massive Kubernetes clusters) for simple microservices when a properly configured Docker/systemd deployment would be significantly more reliable and easier to maintain. Simplicity is a feature.

### Industry Leadership Experience

**21 24. Industry Leadership, Speaking, Startups, and Public Companies.**
My leadership style is internal and execution focused; I do not frequently speak at industry conferences. I consider myself a thought leader in promoting long term engineering judgment advocating for type safety, rigorous testing, and simplicity over adopting the newest hyped framework. My startup like experiences have taught me how to operate across the entire stack with high velocity. However, I understand that operating within a larger, globally distributed company like Canonical requires a shift from "moving fast" to prioritizing absolute stability, extensive written communication, and uncompromising security.

### Education

**25. How did you rank in your final year of high school in mathematics?**
I was a top student. My teachers recognized my ability to independently grasp complex mathematical concepts. I frequently completed advanced problems ahead of the curriculum and naturally thought in terms of systems and algorithms at a young age.

**26. How did you rank in your final year of high school, in your home language?**
I ranked highly, consistently scoring near the top of my class as reflected in my final board examination results.

**27. Please state your high school graduation results and explain the grading system.**
The Indian education system uses a strict percentage based grading system out of 100. I scored **97/100** in my ICSE 10th grade board exams, and **89/100** in my ISC 12th grade board exams.

**28. Can you make a case that you are in the top 5% or 1%?**
Yes, I am confidently in the top 5% of my academic cohort. This is proven by my 97/100 ICSE score, graduating with a 9.2 CGPA in a rigorous Master's program, and successfully passing the highly competitive selection process to become a Research Intern at the Indian Institute of Science (IISc), which accepts only the highest percentile of academic talent in the country.

**29. What sort of high school student were you?**
I was highly analytical but also active outside the classroom. I represented my school at the inter state level in football. Academically, my peers knew me for my ability to perform highly complex calculations mentally and for my deep curiosity about how systems worked.

**30. Which university and degree did you choose?**
I pursued a 5 year Integrated Master of Science (M.Sc.) in Data Science at Thiagarajar College of Engineering (affiliated with Anna University). I selected this institution and degree because the curriculum aligned perfectly with my passion for advanced mathematics and large scale data systems.

**31. Overall, what was your degree result?**
I graduated with a **9.2 CGPA** (on a 10 point scale). This grade reflects my consistent dedication and strong analytical capabilities over a highly demanding 5 year program.

**32. Can you describe any achievements that were truly exceptional?**
Securing a Research Internship at the Indian Institute of Science (IISc) was an exceptional achievement. It is India's premier institute for scientific research, and contributing to work in such a rigorous, high standards academic environment fundamentally shaped my approach to complex problem solving.

**33. What leadership roles did you take on during your education?**
I led multiple engineering teams during university hackathons. I took responsibility for the overall system architecture, delegated tasks based on my peers' strengths, and drove the technical execution from ideation to final deployment.

### Context

**34 38. Mission, Competitors, and Why Canonical.**
Canonical’s mission to deliver secure, open source software universally from the cloud to edge devices deeply resonates with me. As a daily Arch Linux user, I am intimately familiar with the bleeding edge rolling release model, but I deeply respect Ubuntu’s LTS (Long Term Support) model. Ubuntu’s massive dominance in cloud environments stems directly from these predictable LTS upgrade paths, which drastically reduce operational risk and breakages for enterprises compared to rolling release ecosystems. Furthermore, Canonical’s push for reproducible, isolated packaging via Snaps while sometimes debated in enthusiast circles makes absolute engineering sense at an enterprise scale where immutable dependencies and predictable rollbacks are non negotiable. 

Canonical’s primary competitors are Red Hat and SUSE, but Canonical can continue winning by dominating the developer experience and ensuring Ubuntu remains the undisputed default for AI infrastructure. A potential risk is balancing the free, community driven nature of open source with the necessity of driving enterprise revenue. 

I want to work for Canonical because I want to write idiomatic, high quality Python code for an organization that treats software craftsmanship and Linux fundamentals as core values. I am most excited about the opportunity to tackle complex, large scale systems engineering alongside some of the sharpest minds in the open source ecosystem.
